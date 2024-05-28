//
//  Service+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import Foundation
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
    
    // Determines when service is next due, and provides a string describing when service is next due (or if it's overdue). Used on MaintenanceListView
    var nextServiceDueDescription: String {
        let settings = AppSettings()
        var distanceToNextService: Int?
        var daysToNextService: Int?
        var descriptionString = ""
        
        if let odometerDue {
            if let vehicleOdometer = vehicle?.odometer {
                distanceToNextService = odometerDue - vehicleOdometer
            }
        }
        
        if let dateDue {
            if dateDue != sortedServiceRecordsArray.first?.date {
                let dateDifference = Calendar.current.dateComponents([.day], from: Date.now, to: dateDue)
                
                if let daysRemaining = dateDifference.day {
                    daysToNextService = daysRemaining
                }
            }
        }
        
        if let distanceToNextService {
            if distanceToNextService < 0 {
                descriptionString = "Overdue by \(abs(distanceToNextService).formatted()) \(settings.distanceUnit.rawValue)"
            } else {
                descriptionString = "Due in \(distanceToNextService.formatted()) \(settings.distanceUnit.rawValue)"
                
                if daysToNextService != nil {
                    descriptionString.append(" or ")
                }
            }
        }
        
        if let daysToNextService {
            if daysToNextService < 0 {
                descriptionString = "Overdue by \(abs(daysToNextService).formatted()) \(daysToNextService == 1 ? "day" : "days")"
            } else {
                if distanceToNextService == nil {
                    descriptionString = "Due in "
                }
                
                descriptionString.append("\(daysToNextService.formatted()) \(daysToNextService > 1 ? "days" : "day")")
            }
        }
        
        return descriptionString
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
        
        // Cancels any notifications that have been scheduled for this service, so they can be rescheduled, if appropriate
        self.cancelPendingNotifications()
        
        try? context.save()
        
//        updateNotifications()
    }
    
    func delete() {
        let context = DataController.shared.container.viewContext
        
        self.cancelPendingNotifications()
        context.delete(self)
        try? context.save()
    }
    
    func addNewServiceRecord(vehicle: Vehicle, draftServiceRecord: DraftServiceRecord) {
        let context = DataController.shared.container.viewContext
        let newServiceRecord = ServiceRecord(context: context)
        newServiceRecord.service = self
        newServiceRecord.id = UUID()
        newServiceRecord.date = draftServiceRecord.date
        newServiceRecord.odometer = draftServiceRecord.odometer ?? 0
        newServiceRecord.cost = draftServiceRecord.cost
        newServiceRecord.note = draftServiceRecord.note
        newServiceRecord.photos = NSSet(array: draftServiceRecord.photos)
        
        if let odometer = draftServiceRecord.odometer {
            if odometer > vehicle.odometer {
                vehicle.odometer = odometer
            }
        }
        
        // Cancels any notifications that have been scheduled for this service, so they can be rescheduled, if appropriate
        self.cancelPendingNotifications()
        
        try? context.save()
        
//        updateNotifications()
    }
    
    
    // MARK: - Notification Scheduling Methods
    
    // updates notifications and recalculates when service is due, after changes are made to the service itself
    func updateNotifications(vehicle: Vehicle) {
        let context = DataController.shared.container.viewContext
        let settings = AppSettings()
        
        // Reschedule all pending date-based notifications, as long as the alert date has not passed, to ensure that any devices syncing through iCloud have local notifications scheduled, as appropriate
        if self.notificationScheduled == true {
            if let dateDue = self.dateDue {
                if let alertDate = Calendar.current.date(byAdding: .day, value: Int(-settings.daysBeforeMaintenance), to: dateDue) {
                    if alertDate > Date.now {
                        // Remove the date-based notification
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.timeBasedNotificationIdentifier])
                        self.notificationScheduled = false
                        try? context.save()
                        print("canceled date-based notification")
                    }
                }
            }
        }
        
        // Sets up notifications for any service that is due, but does not yet have a notification scheduled; this ensures that each device syncing with iCloud gets its own local notifications, when appropriate
        if self.notificationScheduled == false {
            if let dateDue = self.dateDue {
                if let alertDate = Calendar.current.date(byAdding: .day, value: Int(-settings.daysBeforeMaintenance), to: dateDue) {
                    if dateDue > Date.now && alertDate > Date.now {
                        self.scheduleNotificationOnDate(alertDate, for: vehicle)
                    } else if dateDue > Date.now && alertDate < Date.now {
                        self.scheduleNotificationForTomorrow(for: vehicle)
                    }
                }
            }
            
            if let odometerDue = self.odometerDue {
                let distanceToNextService = odometerDue - vehicle.odometer
                
                if distanceToNextService <= settings.distanceBeforeMaintenance && distanceToNextService >= 0 {
                    self.scheduleNotificationForTomorrow(for: vehicle)
                }
            }
        }
    }
    
    func cancelPendingNotifications() {
        let context = DataController.shared.container.viewContext
        if self.notificationScheduled == true {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.timeBasedNotificationIdentifier, self.distanceBasedNotificationIdentifier])
            self.notificationScheduled = false
            try? context.save()
            print("Cancelled notification")
        }
    }
    
    // Schedule notification based on time interval
    func scheduleNotificationOnDate(_ date: Date, for vehicle: Vehicle) {
        let context = DataController.shared.container.viewContext
        let content = UNMutableNotificationContent()
        content.title = "Time for Maintenance!"
        content.body = "\(self.name) due soon for \(vehicle.name)"
        content.sound = UNNotificationSound.default
        
        let components = Calendar.current.dateComponents([.day, .month, .year], from: date)
        var dateComponents = DateComponents()
        dateComponents.day = components.day
        dateComponents.month = components.month
        dateComponents.year = components.year
        dateComponents.hour = 10
        
        #if DEBUG
        // Temporary notifications, for testing
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: timeBasedNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        #else
        // Production notification timelines
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: timeBasedNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        #endif
        
        print("Alert Date: \(date.formatted(date: .numeric, time: .omitted))")
        
        self.notificationScheduled = true
        
        try? context.save()
    }
    
    // Schedule notification based on distance interval
    func scheduleNotificationForTomorrow(for vehicle: Vehicle) {
        let context = DataController.shared.container.viewContext
        let content = UNMutableNotificationContent()
        content.title = "Time for Maintenance!"
        content.body = "\(self.name) due soon for \(vehicle.name)"
        content.sound = UNNotificationSound.default
        
        let alertDate = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
        let components = Calendar.current.dateComponents([.day], from: alertDate)
        var dateComponents = DateComponents()
        dateComponents.day = components.day
        dateComponents.hour = 10
        
        #if DEBUG
        // Temporary notifications, for testing
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: distanceBasedNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        #else
        // Production notification timelines
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: distanceBasedNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        #endif
        
        print("Notification scheduled for tomorrow!")
        
        self.notificationScheduled = true
        
        try? context.save()
    }
}
