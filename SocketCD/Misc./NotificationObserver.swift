//
//  NotificationObserver.swift
//  SocketCD
//
//  Created by Justin Risner on 11/11/25.
//

import CoreData
import Combine

final class NotificationObserver {
    static let shared = NotificationObserver()
    private var cancellable: AnyCancellable?

    private init() {
        cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main) // Prevents rapid firing
            .sink { _ in
                Task {
                    await NotificationManager.shared.refreshAllNotifications()
                }
            }
    }
}
