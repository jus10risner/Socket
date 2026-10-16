//
//  NotificationManagerTests.swift
//  SocketCDTests
//

import CoreData
import Foundation
import Testing
import UserNotifications
@testable import SocketCD

@MainActor
struct NotificationManagerTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func maintenanceReminderUsesConfiguredLeadTime() throws {
        let now = try date(year: 2026, month: 1, day: 1, hour: 12)
        let dueDate = try date(year: 2026, month: 2, day: 1, hour: 15)

        let deliveryDate = NotificationManager.maintenanceDeliveryDate(
            dueDate: dueDate,
            daysBefore: 14,
            now: now,
            calendar: calendar
        )

        let expectedDate = try date(year: 2026, month: 1, day: 18, hour: 9)
        #expect(deliveryDate == expectedDate)
    }

    @Test func maintenanceReminderUsesNextNineAMWhenLeadDateHasPassed() throws {
        let now = try date(year: 2026, month: 1, day: 20, hour: 12)
        let dueDate = try date(year: 2026, month: 1, day: 25, hour: 15)

        let deliveryDate = NotificationManager.maintenanceDeliveryDate(
            dueDate: dueDate,
            daysBefore: 14,
            now: now,
            calendar: calendar
        )

        let expectedDate = try date(year: 2026, month: 1, day: 21, hour: 9)
        #expect(deliveryDate == expectedDate)
    }

    @Test func odometerReminderUsesFullIntervalFromActivity() throws {
        let lastActivity = try date(year: 2026, month: 3, day: 2, hour: 16)
        let now = try date(year: 2026, month: 3, day: 2, hour: 17)

        let deliveryDate = NotificationManager.odometerReminderDeliveryDate(
            lastActivityDate: lastActivity,
            intervalDays: 14,
            now: now,
            calendar: calendar
        )

        let expectedDate = try date(year: 2026, month: 3, day: 16, hour: 9)
        #expect(deliveryDate == expectedDate)
    }

    @Test func enablingOdometerRemindersResetsEveryVehicleBaseline() throws {
        let controller = TestDataController()
        let firstVehicle = Vehicle(context: controller.context)
        let secondVehicle = Vehicle(context: controller.context)
        firstVehicle.lastOdometerLogAt = try date(year: 2025, month: 1, day: 1)
        secondVehicle.lastOdometerLogAt = nil
        try controller.context.save()
        let enableDate = try date(year: 2026, month: 4, day: 10, hour: 13)

        NotificationManager.shared.resetOdometerReminderBaseline(
            now: enableDate,
            context: controller.context
        )

        #expect(firstVehicle.lastOdometerLogAt == enableDate)
        #expect(secondVehicle.lastOdometerLogAt == enableDate)
        #expect(!controller.context.hasChanges)
    }

    @Test func distanceCrossingReplacesAFutureTimeCandidate() throws {
        let now = try date(year: 2026, month: 5, day: 1, hour: 12)
        let timeDelivery = try date(year: 2026, month: 5, day: 10, hour: 9)
        let distanceDelivery = try date(year: 2026, month: 5, day: 2, hour: 9)
        let existingEntry = MaintenanceNotificationLedger.Entry(
            cycleID: UUID().uuidString,
            threshold: .time,
            scheduledFor: timeDelivery
        )

        let selection = NotificationManager.maintenanceSelection(
            existingEntry: existingEntry,
            timeDeliveryDate: timeDelivery,
            distanceIsEligible: true,
            distanceDeliveryDate: distanceDelivery,
            now: now
        )

        #expect(selection?.threshold == .distance)
        #expect(selection?.deliveryDate == distanceDelivery)
    }

    @Test func completedTimeCandidateSuppressesDistanceForTheCycle() throws {
        let now = try date(year: 2026, month: 5, day: 10, hour: 12)
        let existingEntry = MaintenanceNotificationLedger.Entry(
            cycleID: UUID().uuidString,
            threshold: .time,
            scheduledFor: try date(year: 2026, month: 5, day: 10, hour: 9)
        )

        let selection = NotificationManager.maintenanceSelection(
            existingEntry: existingEntry,
            timeDeliveryDate: nil,
            distanceIsEligible: true,
            distanceDeliveryDate: try date(year: 2026, month: 5, day: 11, hour: 9),
            now: now
        )

        #expect(selection == nil)
    }

    @Test func localLedgerPersistsWinnerAndResetsWithANewCycle() throws {
        let suiteName = "NotificationManagerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let ledger = MaintenanceNotificationLedger(defaults: defaults)
        let serviceID = UUID()
        let firstCycleID = UUID().uuidString
        let entry = MaintenanceNotificationLedger.Entry(
            cycleID: firstCycleID,
            threshold: .distance,
            scheduledFor: try date(year: 2026, month: 6, day: 1, hour: 9)
        )

        ledger.set(entry, for: serviceID)

        #expect(ledger.entry(for: serviceID) == entry)
        let nextEntry = MaintenanceNotificationLedger.Entry(
            cycleID: UUID().uuidString,
            threshold: .time,
            scheduledFor: try date(year: 2026, month: 7, day: 1, hour: 9)
        )
        ledger.set(nextEntry, for: serviceID)
        #expect(ledger.entry(for: serviceID) == nextEntry)
    }

    @Test func legacyRecordWithoutUUIDUsesItsPermanentObjectID() throws {
        let controller = TestDataController()
        let record = ServiceRecord(context: controller.context)
        record.id = nil
        try controller.context.save()

        let cycleID = NotificationManager.maintenanceCycleID(for: record)

        #expect(cycleID == record.objectID.uriRepresentation().absoluteString)
        #expect(!cycleID.isEmpty)
    }

    @Test func reconciliationAddsDesiredAndRemovesObsoleteRequests() async throws {
        let center = TestNotificationCenterClient()
        center.pending = [notificationRequest(identifier: "socket.obsolete", version: "old")]
        let suiteName = "NotificationManagerReconciliationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "didMigrateLegacyNotificationRequests")
        let manager = NotificationManager(center: center, defaults: defaults)
        let desired = notificationRequest(identifier: "socket.maintenance", version: "new")

        await manager.reconcileRequestsForTesting([desired])

        #expect(center.added.map(\.identifier) == [desired.identifier])
        #expect(center.removedPending.contains("socket.obsolete"))
    }

    @Test func reconciliationDoesNotRepeatAnAlreadyDeliveredRequest() async throws {
        let center = TestNotificationCenterClient()
        let delivered = notificationRequest(identifier: "socket.maintenance", version: "same")
        center.delivered = [delivered]
        let suiteName = "NotificationManagerReconciliationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "didMigrateLegacyNotificationRequests")
        let manager = NotificationManager(center: center, defaults: defaults)

        await manager.reconcileRequestsForTesting([delivered])

        #expect(center.added.isEmpty)
        #expect(center.removedPending.contains(delivered.identifier))
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0
    ) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour
        )))
    }

    private func notificationRequest(identifier: String, version: String) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.userInfo["notificationVersion"] = version
        return UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
    }

}

@MainActor
private final class TestNotificationCenterClient: NotificationCenterClient {
    var authorized = true
    var pending: [UNNotificationRequest] = []
    var delivered: [UNNotificationRequest] = []
    var added: [UNNotificationRequest] = []
    var removedPending: [String] = []
    var removedDelivered: [String] = []

    func isAuthorized() async -> Bool { authorized }
    func pendingRequests() async -> [UNNotificationRequest] { pending }
    func deliveredRequests() async -> [UNNotificationRequest] { delivered }
    func add(_ request: UNNotificationRequest) async throws { added.append(request) }
    func removePending(withIdentifiers identifiers: [String]) { removedPending += identifiers }
    func removeDelivered(withIdentifiers identifiers: [String]) { removedDelivered += identifiers }
    func removeAllPending() { pending.removeAll() }
    func removeAllDelivered() { delivered.removeAll() }
}
