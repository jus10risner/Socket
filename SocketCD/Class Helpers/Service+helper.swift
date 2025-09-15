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
    
    func updateAndSave(draftService: DraftService, selectedInterval: ServiceIntervalTypes) {
        let context = DataController.shared.container.viewContext
        
        if selectedInterval == .distance {
            draftService.timeInterval = 0
        } else if selectedInterval == .time {
            draftService.distanceInterval = 0
        }
        
        self.name = draftService.name
        self.distanceInterval = draftService.distanceInterval ?? 0
        self.timeInterval = draftService.timeInterval ?? 0
        self.monthsInterval = draftService.monthsInterval
        self.note = draftService.serviceNote
        
        if let vehicle = self.vehicle {
            self.updateNotifications(vehicle: vehicle)
        }
        
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
                svc.updateNotifications(vehicle: vehicle)
            }
        }
        
        try? context.save()
    }
    
    
    // MARK: - Notification Scheduling Methods
    
    func updateNotifications(vehicle: Vehicle) {
        let context = DataController.shared.container.viewContext
        let settings = AppSettings()
        let now = Date()

        // Get pending notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let pendingIDs = Set(requests.map(\.identifier))
            var didSchedule = false

            // === TIME-BASED ===
            if let dateDue = self.dateDue,
               let alertDate = Calendar.current.date(byAdding: .day, value: -settings.daysBeforeMaintenance, to: dateDue),
               dateDue > now, alertDate > now {

                if !pendingIDs.contains(self.timeBasedNotificationIdentifier) {
                    self.scheduleNotificationOnDate(alertDate, for: vehicle) {
                        didSchedule = true
                        self.saveNotificationFlagIfNeeded(didSchedule, context: context)
                    }
                }
            } else {
                // Cancel time-based notifications, if no longer due
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.timeBasedNotificationIdentifier])
            }

            // === DISTANCE-BASED ===
            if let odometerDue = self.odometerDue {
                let distanceRemaining = odometerDue - vehicle.odometer
                if distanceRemaining <= settings.distanceBeforeMaintenance, distanceRemaining >= 0 {
                    if !pendingIDs.contains(self.distanceBasedNotificationIdentifier) {
                        self.scheduleNotificationMomentarily(for: vehicle) {
                            didSchedule = true
                            self.saveNotificationFlagIfNeeded(didSchedule, context: context)
                        }
                    }
                } else {
                    // Cancel distance-based notifications, if no longer relevant
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.distanceBasedNotificationIdentifier])
                }
            }

            // If nothing was scheduled and both are no longer valid
            if !didSchedule {
                DispatchQueue.main.async {
                    let context = DataController.shared.container.viewContext
                    self.notificationScheduled = false
                    try? context.save()
                }
            }
        }
    }
    
    // Cancels any pending notifications for a given service (used before deleting a service)
    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.timeBasedNotificationIdentifier, self.distanceBasedNotificationIdentifier])
        let context = DataController.shared.container.viewContext
        self.notificationScheduled = false
        
        try? context.save()
        
        print("Cancelled notifications")
    }
    
    // Sets the notificationScheduled flag to true, when a notification is scheduled; extracted this into its own function to prevent duplication of code
    private func saveNotificationFlagIfNeeded(_ didSchedule: Bool, context: NSManagedObjectContext) {
        guard didSchedule else { return }
        DispatchQueue.main.async {
            self.notificationScheduled = true
            try? context.save()
        }
    }
    
    // Schedule notification based on time interval
    func scheduleNotificationOnDate(_ date: Date, for vehicle: Vehicle, completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            guard !requests.contains(where: { $0.identifier == self.timeBasedNotificationIdentifier }) else {
                completion()
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Time for Maintenance!"
            content.body = "\(self.name) due soon for \(vehicle.name)"
            content.sound = .default

            #if DEBUG
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            #else
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
            var dateComponents = components
            dateComponents.hour = 10 // Notify at 10 AM
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            #endif

            let request = UNNotificationRequest(identifier: self.timeBasedNotificationIdentifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            
            print("Scheduled time-based notification for \(date.formatted(date: .numeric, time: .omitted))")
            
            completion()
        }
    }
    
    // Schedule notification with 30-second delay, based on distance interval
    func scheduleNotificationMomentarily(for vehicle: Vehicle, completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            guard !requests.contains(where: { $0.identifier == self.distanceBasedNotificationIdentifier }) else {
                completion()
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Time for Maintenance!"
            content.body = "\(self.name) due soon for \(vehicle.name)"
            content.sound = .default

            #if DEBUG
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            #else
            let delaySeconds: TimeInterval = 30
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)
            #endif

            let request = UNNotificationRequest(identifier: self.distanceBasedNotificationIdentifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            
            print("Scheduled distance-based notification for tomorrow")
            
            completion()
        }
    }
}
