//
//  CloudKitSyncMonitor.swift
//  SocketCD
//
//  Created by Justin Risner on 10/13/25.
//

import SwiftUI
import CoreData

@MainActor
class CloudKitSyncMonitor: ObservableObject {
    @Published var isSyncing = false

    init(container: NSPersistentCloudKitContainer) {
        Task {
            for await notification in NotificationCenter.default.notifications(
                named: NSPersistentCloudKitContainer.eventChangedNotification,
                object: container
            ) {
                guard let event = notification.userInfo?[
                    NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                ] as? NSPersistentCloudKitContainer.Event else {
                    continue
                }

                // If the event has no endDate yet, it's still in progress
                isSyncing = (event.endDate == nil)
            }
        }
    }
}
