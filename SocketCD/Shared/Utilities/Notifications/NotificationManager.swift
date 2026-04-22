//
//  NotificationManager.swift
//  SocketCD
//
//  Created by Justin Risner on 11/11/25.
//

import SwiftUI
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() {}

    @MainActor
    func refreshAllNotifications() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("Notifications not authorized.")
            return
        }

        let context = DataController.shared.container.viewContext
        let vehicles = (try? context.fetch(Vehicle.fetchRequest())) ?? []
        
        for vehicle in vehicles {
            guard let services = vehicle.services as? Set<Service> else { continue }

            for service in services {
                await service.evaluateNotifications(for: vehicle)
            }
        }
    }
    
    // Used to update all notifications, when alert ranges are modified in app settings
    @MainActor
    func cancelAndRescheduleAllNotifications() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("Notifications not authorized.")
            return
        }

        let context = DataController.shared.container.viewContext
        let vehicles = (try? context.fetch(Vehicle.fetchRequest())) ?? []
        let allServices: [Service] = vehicles
            .compactMap { $0.services as? Set<Service> }
            .flatMap { Array($0) }

        // Cancel notifications for each service and clear lastScheduleNotification values
        for service in allServices {
            // Cancel time-based if one was scheduled
            if service.lastScheduledNotificationDate != nil {
                NotificationScheduler.cancelTimeBased(for: service)
                service.lastScheduledNotificationDate = nil
            }

            // Cancel distance-based if one was scheduled
            if service.lastScheduledNotificationOdometer != nil {
                NotificationScheduler.cancelDistanceBased(for: service)
                service.lastScheduledNotificationOdometer = nil
            }
        }

        try? context.save()

        await refreshAllNotifications()
    }
}
