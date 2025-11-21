//
//  Service+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData
import SwiftUI

extension Service {
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }
    
    var distanceInterval: Int {
        get { Int(distanceInterval_) }
        set { distanceInterval_ = Int64(newValue) }
    }
    
    var timeInterval: Int {
        get { Int(timeInterval_) }
        set { timeInterval_ = Int64(newValue) }
    }
    
    var monthsInterval: Bool {
        get { monthsInterval_ }
        set { monthsInterval_ = newValue }
    }
    
    var note: String {
        get { note_ ?? "" }
        set { note_ = newValue }
    }
    
    // No longer used, but keeping it here since it exists in CloudKit
    var notificationScheduled: Bool {
        get { notificationScheduled_ }
        set { notificationScheduled_ = newValue }
    }
    
    var distanceBasedNotificationIdentifier: String {
        get { distanceBasedNotificationIdentifier_ ?? "" }
        set { distanceBasedNotificationIdentifier_ = newValue }
    }
    
    var timeBasedNotificationIdentifier: String {
        get { timeBasedNotificationIdentifier_ ?? "" }
        set { timeBasedNotificationIdentifier_ = newValue }
    }
    
    var lastScheduledNotificationDate: Date? {
        get { lastScheduledNotificationDate_ }
        set { lastScheduledNotificationDate_ = newValue }
    }
    
    var lastScheduledNotificationOdometer: Int? {
        get { lastScheduledNotificationOdometer_ == 0 ? nil : Int(lastScheduledNotificationOdometer_) }
        set { lastScheduledNotificationOdometer_ = newValue == nil ? 0 : Int64(newValue!) }
    }
    
    var sortedServiceRecordsArray: [ServiceRecord] {
        let set = serviceRecords as? Set<ServiceRecord> ?? []
        
        return set.sorted {
            $0.date > $1.date
        }
    }
    
    // Uses a milesPerDay value to estimate how long until a service is due; this helps normalize miles until due and days until due
    func estimatedDaysUntilDue(currentOdometer: Int, milesPerDay: Int = 30) -> Int? {
        let now = Date()
        
        let daysUntilDue = dateDue.map { Calendar.current.dateComponents([.day], from: now, to: $0).day } ?? nil

        let estimatedDaysUntilOdometerDue = odometerDue.map { max(0, $0 - currentOdometer) / milesPerDay }

        switch (daysUntilDue, estimatedDaysUntilOdometerDue) {
        case let (d?, e?): return min(d, e)
        case let (d?, nil): return d
        case let (nil, e?): return e
        default: return nil
        }
    }
    
    
    // MARK: - Computed Properties
    
    // Date next service is due (if a date interval is given)
    var dateDue: Date? {
        if let firstRecordDate = sortedServiceRecordsArray.first?.date {
            if timeInterval != 0 {
                if monthsInterval == true {
                    return Calendar.current.date(byAdding: .month, value: Int(timeInterval), to: firstRecordDate)
                } else {
                    return Calendar.current.date(byAdding: .year, value: Int(timeInterval), to: firstRecordDate)
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // Odometer reading when next service is due (if a distance interval is given)
    var odometerDue: Int? {
        if let firstRecordOdometer = sortedServiceRecordsArray.first?.odometer {
            if distanceInterval != 0 {
                return firstRecordOdometer + distanceInterval
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // Returns the service status of a service, and schedules a notification, when appropriate
    var serviceStatus: ServiceStatus {
        let settings = AppSettings()
        
        var mileageStatus = ServiceStatus.notDue
        var dateStatus = ServiceStatus.notDue
        
        if let odometerDue = self.odometerDue {
            if let vehicleOdometer = self.vehicle?.odometer {
                let distanceToNextService = odometerDue - vehicleOdometer
                
                if distanceToNextService <= settings.distanceBeforeMaintenance && distanceToNextService >= 0 {
                    mileageStatus = .due
                } else if distanceToNextService < 0 {
                    mileageStatus = .overDue
                } else if distanceToNextService > settings.distanceBeforeMaintenance {
                    mileageStatus = .notDue
                }
            }
        }
        
        if let dateDue = self.dateDue {
            let difference = Calendar.current.dateComponents([.day], from: Date.now, to: dateDue)
            
            if let daysRemaining = difference.day {
                if daysRemaining <= settings.daysBeforeMaintenance && dateDue >= Date.now {
                    dateStatus = .due
                } else if dateDue < Date.now {
                    dateStatus = .overDue
                } else if daysRemaining > settings.daysBeforeMaintenance {
                    dateStatus = .notDue
                }
            }
        }
        
        if mileageStatus == .overDue || dateStatus == .overDue {
            return .overDue
        } else if mileageStatus == .due || dateStatus == .due {
            return .due
        } else {
            return .notDue
        }
    }
    
    // determine service status color
    var indicatorColor: Color {
        switch serviceStatus {
        case .overDue:
            return .red
        case .due:
            return .yellow
        case .notDue:
            return .green
        }
    }
    
    func daysUntilDue(from date: Date = .now) -> Int? {
        guard let dateDue else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: dateDue).day
    }

    func milesUntilDue(currentOdometer: Int) -> Int? {
        guard let odometerDue else { return nil }
        return odometerDue - currentOdometer
    }
    
    // Returns progress toward this service as a value between 0 (just reset) and 1 (overdue)
    func progress(currentOdometer: Int) -> CGFloat {
       // Distance-based progress
        let odometerProgress: CGFloat
        
        if let milesLeft = milesUntilDue(currentOdometer: currentOdometer), distanceInterval > 0 {
           odometerProgress = max(0, CGFloat(milesLeft) / CGFloat(distanceInterval))
        } else {
           odometerProgress = 0
        }

        // Time-based progress
        let timeProgress: CGFloat
        
        if let daysLeft = daysUntilDue() {
           let totalDays: CGFloat = monthsInterval ? CGFloat(timeInterval * 30) : CGFloat(timeInterval * 365)
           timeProgress = max(0, CGFloat(daysLeft) / totalDays)
        } else {
           timeProgress = 0
        }

        // Progress is the greater of the two, capped at 1
        return min(1, max(odometerProgress, timeProgress))
    }
    
    // Returns a string that describes when service is next due (or by how much service is overdue). Used on VehicleDashboardView and MaintenanceListView
    func nextDueDescription(currentOdometer: Int) -> String {
        let settings = AppSettings()

        // Compute values once
        let days = daysUntilDue() ?? 0
        let miles = milesUntilDue(currentOdometer: currentOdometer) ?? 0

        // Check if both values exist
        let hasDays = daysUntilDue() != nil
        let hasMiles = milesUntilDue(currentOdometer: currentOdometer) != nil

        // Case 1: Both values missing
        guard hasDays || hasMiles else { return "No Service Logged" }

        // Case 2: Any overdue?
        if days < 0 && miles < 0 {
            // Both overdue → pick the larger overdue
            if abs(days) >= abs(miles) {
                return "Overdue by \(pluralize(abs(days), unit: "day"))"
            } else {
                return "Overdue by \(abs(miles).formatted()) \(settings.distanceUnit.abbreviated)"
            }
        } else if days < 0 {
            return "Overdue by \(pluralize(abs(days), unit: "day"))"
        } else if miles < 0 {
            return "Overdue by \(abs(miles).formatted()) \(settings.distanceUnit.abbreviated)"
        }

        // Case 3: Not overdue
        switch (hasDays, hasMiles) {
        case (true, true):
            return "Due in \(miles.formatted()) \(settings.distanceUnit.abbreviated) or \(pluralize(days, unit: "day"))"
        case (true, false):
            return "Due in \(pluralize(days, unit: "day"))"
        case (false, true):
            return "Due in \(miles.formatted()) \(settings.distanceUnit.abbreviated)"
        default:
            return "No Service Logged"
        }
    }
    
    // Accepts a singular unit type and appends an 's' to make it plural, when appropriate; formats the count, so it displays as users expect
    func pluralize(_ count: Int, unit: String) -> String {
        return count == 1 ? "\(count.formatted()) \(unit)" : "\(count.formatted()) \(unit)s"
    }
    
    // A String describing the service interval for a given service
    var intervalDescription: String {
        let settings = AppSettings()
        var components: [String] = []

        if distanceInterval != 0 {
            let distance = "\(distanceInterval.formatted()) \(settings.distanceUnit.abbreviated)"
            components.append(distance)
        }
        
        if timeInterval != 0 {
            if monthsInterval == true {
                components.append(pluralize(timeInterval, unit: "month"))
            } else {
                components.append(pluralize(timeInterval, unit: "year"))
            }
        }

        return components.joined(separator: " or ")
    }
    
    
    // MARK: - CRUD Methods
    
    func updateAndSave(draftService: DraftService) {
        let context = DataController.shared.container.viewContext
        
        self.name = draftService.name
        self.distanceInterval = draftService.distanceInterval ?? 0
        self.timeInterval = draftService.timeInterval ?? 0
        self.monthsInterval = draftService.monthsInterval
        self.note = draftService.serviceNote
        
//        if let vehicle = self.vehicle {
//            self.updateNotifications(vehicle: vehicle)
//        }
        
        try? context.save()
    }
    
    func addNewServiceRecord(draftServiceLog: DraftServiceLog, allServices: [Service]) {
        let context = DataController.shared.container.viewContext
        
        // Delete baseline service log, if one exists, before adding a user-created service log
        if let baselineServiceLog = sortedServiceRecordsArray.first(where: { $0.serviceLog?.isBaseline == true }) {
            context.delete(baselineServiceLog)
        }
        
        // Create a new ServiceLog
        let log = ServiceLog(context: context)
        log.id = UUID()
        log.date = draftServiceLog.date
        log.odometer = draftServiceLog.odometer ?? 0
        log.cost = draftServiceLog.cost
        log.note = draftServiceLog.note
        log.photos = NSSet(array: draftServiceLog.photos)

        // Resolve selected services from IDs
        let selectedServices = draftServiceLog.selectedServiceIDs.compactMap { id in
            allServices.first(where: { $0.id == id })
        }

        // Create a record for each selected service
        for svc in selectedServices {
            let record = ServiceRecord(context: context)
            record.id = UUID()
            record.service = svc
            record.serviceLog = log
            record.date = draftServiceLog.date
            record.odometer = draftServiceLog.odometer ?? 0
        }

        // Update vehicle odometer if needed
        for svc in selectedServices {
            if let vehicle = svc.vehicle,
               let draftOdo = draftServiceLog.odometer,
               draftOdo > vehicle.odometer {
                vehicle.odometer = draftOdo
//                svc.updateNotifications(vehicle: vehicle)
            }
        }
        
        try? context.save()
    }
    
    
    // MARK: - Notification Scheduling
    
    /// This function should be called after any service record/service/settings change that could affect notification logic.
    @MainActor
    func evaluateNotifications(for vehicle: Vehicle) async {
        let now = Date()
        let settings = AppSettings()
        let context = DataController.shared.container.viewContext

        // --- TIME-BASED ---
        if let dateDue = self.dateDue,
           let alertDate = Calendar.current.date(byAdding: .day, value: -settings.daysBeforeMaintenance, to: dateDue),
           dateDue > now, alertDate > now {
            if lastScheduledNotificationDate != dateDue {
                NotificationScheduler.scheduleTimeBased(for: self, vehicle: vehicle, on: alertDate)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.lastScheduledNotificationDate = dateDue
                    try? context.save()
                }
            }
        } else {
            // Cancel and clear when there is no due date, or it's no longer valid
            NotificationScheduler.cancelTimeBased(for: self)
            if lastScheduledNotificationDate != nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.lastScheduledNotificationDate = nil
                    try? context.save()
                }
            }
        }

        // --- DISTANCE-BASED ---
        if let odometerDue = self.odometerDue {
            let remaining = odometerDue - vehicle.odometer
            if remaining <= settings.distanceBeforeMaintenance, remaining >= 0 {
                if lastScheduledNotificationOdometer != odometerDue {
                    NotificationScheduler.scheduleDistanceBased(for: self, vehicle: vehicle)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.lastScheduledNotificationOdometer = odometerDue
                        try? context.save()
                    }
                }
            } else {
                // Out of range: cancel and clear
                NotificationScheduler.cancelDistanceBased(for: self)
                if lastScheduledNotificationOdometer != nil {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.lastScheduledNotificationOdometer = nil
                        try? context.save()
                    }
                }
            }
        } else {
            // No odometer due: cancel and clear
            NotificationScheduler.cancelDistanceBased(for: self)
            if lastScheduledNotificationOdometer != nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.lastScheduledNotificationOdometer = nil
                    try? context.save()
                }
            }
        }
    }

}

enum NotificationScheduler {
    // MARK: Time-Based
    // Schedules a time-based notification once per due date
    static func scheduleTimeBased(for service: Service, vehicle: Vehicle, on date: Date) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            guard !requests.contains(where: { $0.identifier == service.timeBasedNotificationIdentifier }) else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Time for Maintenance!"
            content.body = "\(service.name) due soon for \(vehicle.name)"
            content.sound = .default

            #if DEBUG
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            #else
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            #endif

            let request = UNNotificationRequest(
                identifier: service.timeBasedNotificationIdentifier,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
            print("Scheduled time-based notification for \(service.name)")
        }
    }

    static func cancelTimeBased(for service: Service) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [service.timeBasedNotificationIdentifier]
        )
    }

    // MARK: Distance-Based
    // Schedules a distance-based notification once per due odometer value
    static func scheduleDistanceBased(for service: Service, vehicle: Vehicle) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            guard !requests.contains(where: { $0.identifier == service.distanceBasedNotificationIdentifier }) else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Maintenance Due Soon!"
            content.body = "\(service.name) will be due soon for \(vehicle.name)"
            content.sound = .default

            #if DEBUG
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            #else
            // 30-minute delay
            let delaySeconds: TimeInterval = 30 * 60
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)
            #endif

            let request = UNNotificationRequest(
                identifier: service.distanceBasedNotificationIdentifier,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
            print("Scheduled distance-based notification for \(service.name)")
        }
    }

    static func cancelDistanceBased(for service: Service) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [service.distanceBasedNotificationIdentifier]
        )
    }
}

