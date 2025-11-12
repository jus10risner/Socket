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

        vehicles.forEach { vehicle in
            (vehicle.services ?? []).forEach { service in
                if let service = service as? Service {
                    service.evaluateNotifications(for: vehicle)
                }
            }
        }
    }
}
