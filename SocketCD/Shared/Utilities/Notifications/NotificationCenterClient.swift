//
//  NotificationCenterClient.swift
//  SocketCD
//

import UserNotifications

@MainActor
protocol NotificationCenterClient {
    func isAuthorized() async -> Bool
    func pendingRequests() async -> [UNNotificationRequest]
    func deliveredRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePending(withIdentifiers identifiers: [String])
    func removeDelivered(withIdentifiers identifiers: [String])
    func removeAllPending()
    func removeAllDelivered()
}

@MainActor
struct SystemNotificationCenterClient: NotificationCenterClient {
    private let center = UNUserNotificationCenter.current()

    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return [.authorized, .provisional, .ephemeral].contains(status)
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func deliveredRequests() async -> [UNNotificationRequest] {
        await center.deliveredNotifications().map(\.request)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func removePending(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeDelivered(withIdentifiers identifiers: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removeAllPending() {
        center.removeAllPendingNotificationRequests()
    }

    func removeAllDelivered() {
        center.removeAllDeliveredNotifications()
    }
}
