//
//  NotificationObserver.swift
//  SocketCD
//

import CoreData
import Foundation

final class NotificationObserver {
    static let shared = NotificationObserver()

    private var tasks: [Task<Void, Never>] = []

    private init() {
        tasks.append(Task {
            for await _ in NotificationCenter.default.notifications(
                named: .NSManagedObjectContextDidSave
            ) {
                await NotificationManager.shared.refreshAllNotifications()
            }
        })

        tasks.append(Task {
            for await _ in NotificationCenter.default.notifications(
                named: .NSPersistentStoreRemoteChange,
                object: DataController.shared.container.persistentStoreCoordinator
            ) {
                await NotificationManager.shared.refreshAllNotifications()
            }
        })
    }

    deinit {
        tasks.forEach { $0.cancel() }
    }
}
