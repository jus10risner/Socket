//
//  NotificationManager.swift
//  SocketCD
//

import CoreData
import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private static let identifierPrefix = "socket."
    private static let legacyMigrationKey = "didMigrateLegacyNotificationRequests"
    private var isRefreshing = false
    private var needsAnotherRefresh = false
    private let maintenanceLedger = MaintenanceNotificationLedger()
    private let center: any NotificationCenterClient
    private let defaults: UserDefaults

    private struct DesiredNotification {
        let request: UNNotificationRequest
        let ledgerEntry: MaintenanceNotificationLedger.Entry?
        let serviceID: UUID?
    }

    struct MaintenanceSelection: Equatable {
        let threshold: MaintenanceNotificationLedger.Threshold
        let deliveryDate: Date
    }

    init(
        center: (any NotificationCenterClient)? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.center = center ?? SystemNotificationCenterClient()
        self.defaults = defaults
    }

#if DEBUG
    private enum NotificationTestingError: LocalizedError {
        case notificationsNotAuthorized

        var errorDescription: String? {
            String(localized: "Notifications aren’t authorized for Socket.")
        }
    }
#endif

    func refreshAllNotifications() async {
        if isRefreshing {
            needsAnotherRefresh = true
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        repeat {
            needsAnotherRefresh = false
            await reconcileNotifications()
        } while needsAnotherRefresh
    }

    func cancelAndRescheduleAllNotifications() async {
        await refreshAllNotifications()
    }

#if DEBUG
    func scheduleTestNotification(after delay: TimeInterval = 10) async throws {
        guard await center.isAuthorized() else {
            throw NotificationTestingError.notificationsNotAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Socket Test Notification")
        content.body = String(localized: "Notifications are working as expected.")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, delay),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "socket-test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }
#endif

    func initializeMissingOdometerActivityDates(now: Date = .now) {
        let context = DataController.shared.container.viewContext
        let vehicles = (try? context.fetch(Vehicle.fetchRequest())) ?? []
        var changed = false

        for vehicle in vehicles where vehicle.lastOdometerLogAt == nil {
            vehicle.lastOdometerLogAt = now
            changed = true
        }

        if changed {
            try? context.save()
        }
    }

    /// Starts a new inactivity cycle when the user enables odometer reminders.
    /// Existing activity dates are intentionally replaced so the first reminder
    /// uses the selected interval starting from opt-in.
    func resetOdometerReminderBaseline(
        now: Date = .now,
        context: NSManagedObjectContext? = nil
    ) {
        let context = context ?? DataController.shared.container.viewContext
        let vehicles = (try? context.fetch(Vehicle.fetchRequest())) ?? []

        for vehicle in vehicles {
            vehicle.lastOdometerLogAt = now
        }

        if context.hasChanges {
            try? context.save()
        }
    }

    private func reconcileNotifications() async {
        guard await center.isAuthorized() else { return }

        let desired = desiredNotifications()
        await reconcileNotifications(desired)
    }

    private func reconcileNotifications(_ desired: [String: DesiredNotification]) async {
        let pending = await center.pendingRequests()
        let delivered = await center.deliveredRequests()

        if !defaults.bool(forKey: Self.legacyMigrationKey) {
            center.removeAllPending()
            center.removeAllDelivered()
            defaults.set(true, forKey: Self.legacyMigrationKey)

            for notification in desired.values {
                do {
                    try await center.add(notification.request)
                    recordLedgerEntry(for: notification)
                } catch {
                    print("Unable to schedule notification \(notification.request.identifier): \(error.localizedDescription)")
                }
            }
            return
        }

        let desiredIDs = Set(desired.keys)
        let managedPendingIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        let obsoleteIDs = managedPendingIDs.filter { !desiredIDs.contains($0) }

        center.removePending(withIdentifiers: obsoleteIDs)

        let managedDelivered = delivered.filter {
            $0.identifier.hasPrefix(Self.identifierPrefix)
        }
        let obsoleteDeliveredIDs = managedDelivered
            .map(\.identifier)
            .filter { !desiredIDs.contains($0) }
        center.removeDelivered(withIdentifiers: obsoleteDeliveredIDs)

        for (identifier, notification) in desired {
            let request = notification.request
            if let deliveredRequest = managedDelivered.first(where: {
                $0.identifier == identifier
            }) {
                if notificationVersion(in: deliveredRequest) == notificationVersion(in: request) {
                    recordLedgerEntry(for: notification)
                    center.removePending(withIdentifiers: [identifier])
                    continue
                }

                center.removeDelivered(withIdentifiers: [identifier])
            }

            do {
                try await center.add(request)
                recordLedgerEntry(for: notification)
            } catch {
                print("Unable to schedule notification \(identifier): \(error.localizedDescription)")
            }
        }
    }

#if DEBUG
    func reconcileRequestsForTesting(_ requests: [UNNotificationRequest]) async {
        let desired = Dictionary(uniqueKeysWithValues: requests.map { request in
            (request.identifier, DesiredNotification(
                request: request,
                ledgerEntry: nil,
                serviceID: nil
            ))
        })
        await reconcileNotifications(desired)
    }
#endif

    private func desiredNotifications(now: Date = .now) -> [String: DesiredNotification] {
        let context = DataController.shared.container.viewContext
        let vehicles = (try? context.fetch(Vehicle.fetchRequest())) ?? []
        let settings = AppSettingsStore.shared
        var requests: [String: DesiredNotification] = [:]
        var currentServiceIDs: Set<UUID> = []

        for vehicle in vehicles {
            guard let vehicleID = vehicle.id else { continue }

            for service in vehicle.services as? Set<Service> ?? [] {
                guard let serviceID = service.id else { continue }
                currentServiceIDs.insert(serviceID)

                if let notification = maintenanceNotification(
                    for: service,
                    serviceID: serviceID,
                    vehicle: vehicle,
                    daysBeforeMaintenance: settings.daysBeforeMaintenance,
                    distanceBeforeMaintenance: settings.distanceBeforeMaintenance,
                    now: now
                ) {
                    requests[notification.request.identifier] = notification
                }
            }

            if settings.odometerReminderEnabled,
               let lastLogAt = vehicle.lastOdometerLogAt,
               let request = odometerReminderRequest(
                   vehicle: vehicle,
                   vehicleID: vehicleID,
                   lastLogAt: lastLogAt,
                   intervalDays: settings.odometerReminderIntervalDays,
                   now: now
               ) {
                requests[request.identifier] = DesiredNotification(
                    request: request,
                    ledgerEntry: nil,
                    serviceID: nil
                )
            }
        }

        maintenanceLedger.removeEntries(except: currentServiceIDs)
        return requests
    }

    private func maintenanceNotification(
        for service: Service,
        serviceID: UUID,
        vehicle: Vehicle,
        daysBeforeMaintenance: Int,
        distanceBeforeMaintenance: Int,
        now: Date
    ) -> DesiredNotification? {
        guard let latestRecord = service.sortedServiceRecordsArray.first else {
            maintenanceLedger.removeEntry(for: serviceID)
            return nil
        }
        let cycleID = Self.maintenanceCycleID(for: latestRecord)

        let existingEntry = maintenanceLedger.entry(for: serviceID)
        let entry = existingEntry?.cycleID == cycleID ? existingEntry : nil
        if existingEntry != nil, entry == nil {
            maintenanceLedger.removeEntry(for: serviceID)
        }

        let timeDeliveryDate = service.dateDue.flatMap {
            Self.maintenanceDeliveryDate(
                dueDate: $0,
                daysBefore: daysBeforeMaintenance,
                now: now
            )
        }
        let distanceIsEligible = service.odometerDue.map {
            let remaining = $0 - vehicle.odometer
            return remaining >= 0 && remaining <= max(0, distanceBeforeMaintenance)
        } ?? false

        let distanceDeliveryDate = distanceIsEligible ? nextNineAM(after: now) : nil
        guard let selection = Self.maintenanceSelection(
            existingEntry: entry,
            timeDeliveryDate: timeDeliveryDate,
            distanceIsEligible: distanceIsEligible,
            distanceDeliveryDate: distanceDeliveryDate,
            now: now
        ) else { return nil }

        let ledgerEntry = MaintenanceNotificationLedger.Entry(
            cycleID: cycleID,
            threshold: selection.threshold,
            scheduledFor: selection.deliveryDate
        )
        let request = request(
            identifier: Self.identifier(for: serviceID, kind: "maintenance"),
            title: String(localized: "Upcoming Maintenance"),
            body: String(
                localized: "\(service.name) is due soon for \(vehicle.name)",
                comment: "Maintenance notification body"
            ),
            deliveryDate: selection.deliveryDate,
            version: Self.maintenanceVersion(cycleID: cycleID, threshold: selection.threshold)
        )

        return DesiredNotification(
            request: request,
            ledgerEntry: ledgerEntry,
            serviceID: serviceID
        )
    }

    private func odometerReminderRequest(
        vehicle: Vehicle,
        vehicleID: UUID,
        lastLogAt: Date,
        intervalDays: Int,
        now: Date
    ) -> UNNotificationRequest? {
        guard let deliveryDate = Self.odometerReminderDeliveryDate(
            lastActivityDate: lastLogAt,
            intervalDays: intervalDays,
            now: now
        ) else { return nil }

        return request(
            identifier: Self.identifier(for: vehicleID, kind: "odometer-reminder"),
            title: String(localized: "Update Your Odometer"),
            body: String(
                localized: "It’s been a while since you logged the odometer for \(vehicle.name).",
                comment: "Odometer reminder notification body"
            ),
            deliveryDate: deliveryDate,
            version: String(lastLogAt.timeIntervalSinceReferenceDate)
        )
    }

    private func request(
        identifier: String,
        title: String,
        body: String,
        deliveryDate: Date,
        version: String
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo["notificationVersion"] = version

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: deliveryDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
    }

    private func deliveryDate(on date: Date) -> Date? {
        Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: date
        )
    }

    private func nextNineAM(after date: Date) -> Date? {
        Self.nextNineAM(after: date)
    }

    static func maintenanceDeliveryDate(
        dueDate: Date,
        daysBefore: Int,
        now: Date,
        calendar: Calendar = .current
    ) -> Date? {
        guard dueDate > now,
              let alertDate = calendar.date(
                  byAdding: .day,
                  value: -max(0, daysBefore),
                  to: dueDate
              ),
              let scheduledDate = deliveryDate(on: alertDate, calendar: calendar) else {
            return nil
        }

        return scheduledDate > now
            ? scheduledDate
            : nextNineAM(after: now, calendar: calendar)
    }

    static func odometerReminderDeliveryDate(
        lastActivityDate: Date,
        intervalDays: Int,
        now: Date,
        calendar: Calendar = .current
    ) -> Date? {
        guard let thresholdDate = calendar.date(
            byAdding: .day,
            value: max(1, intervalDays),
            to: lastActivityDate
        ), let scheduledDate = deliveryDate(on: thresholdDate, calendar: calendar) else {
            return nil
        }

        return scheduledDate > now
            ? scheduledDate
            : nextNineAM(after: now, calendar: calendar)
    }

    static func maintenanceSelection(
        existingEntry: MaintenanceNotificationLedger.Entry?,
        timeDeliveryDate: Date?,
        distanceIsEligible: Bool,
        distanceDeliveryDate: Date?,
        now: Date
    ) -> MaintenanceSelection? {
        if let existingEntry {
            guard existingEntry.scheduledFor > now else { return nil }

            if existingEntry.threshold == .distance {
                return MaintenanceSelection(
                    threshold: .distance,
                    deliveryDate: existingEntry.scheduledFor
                )
            }
        }

        if distanceIsEligible,
           let distanceDeliveryDate,
           let timeDeliveryDate,
           timeDeliveryDate > now {
            return MaintenanceSelection(
                threshold: .distance,
                deliveryDate: distanceDeliveryDate
            )
        }

        if let timeDeliveryDate {
            return MaintenanceSelection(threshold: .time, deliveryDate: timeDeliveryDate)
        }

        if distanceIsEligible, let distanceDeliveryDate {
            return MaintenanceSelection(
                threshold: .distance,
                deliveryDate: distanceDeliveryDate
            )
        }

        return nil
    }

    static func maintenanceCycleID(for record: ServiceRecord) -> String {
        record.id?.uuidString ?? record.objectID.uriRepresentation().absoluteString
    }

    private static func deliveryDate(on date: Date, calendar: Calendar) -> Date? {
        calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)
    }

    private static func nextNineAM(
        after date: Date,
        calendar: Calendar = .current
    ) -> Date? {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 9),
            matchingPolicy: .nextTime
        )
    }

    private func notificationVersion(in request: UNNotificationRequest) -> String? {
        if let version = request.content.userInfo["notificationVersion"] as? String {
            return version
        }
        if let version = request.content.userInfo["notificationVersion"] as? Double {
            return String(version)
        }
        return nil
    }

    private func recordLedgerEntry(for notification: DesiredNotification) {
        guard let entry = notification.ledgerEntry,
              let serviceID = notification.serviceID else { return }

        maintenanceLedger.set(entry, for: serviceID)
    }

    private static func maintenanceVersion(
        cycleID: String,
        threshold: MaintenanceNotificationLedger.Threshold
    ) -> String {
        "\(cycleID).\(threshold.rawValue)"
    }

    private static func identifier(for id: UUID, kind: String) -> String {
        "\(identifierPrefix)\(kind).\(id.uuidString)"
    }
}
