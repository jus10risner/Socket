//
//  MaintenanceNotificationLedger.swift
//  SocketCD
//

import Foundation

struct MaintenanceNotificationLedger {
    enum Threshold: String, Codable {
        case time
        case distance
    }

    struct Entry: Codable, Equatable {
        let cycleID: String
        let threshold: Threshold
        let scheduledFor: Date
    }

    private static let storageKey = "maintenanceNotificationLedger"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func entry(for serviceID: UUID) -> Entry? {
        entries()[serviceID.uuidString]
    }

    func set(_ entry: Entry, for serviceID: UUID) {
        var entries = entries()
        entries[serviceID.uuidString] = entry
        save(entries)
    }

    func removeEntry(for serviceID: UUID) {
        var entries = entries()
        entries.removeValue(forKey: serviceID.uuidString)
        save(entries)
    }

    func removeEntries(except serviceIDs: Set<UUID>) {
        let validKeys = Set(serviceIDs.map(\.uuidString))
        let filtered = entries().filter { validKeys.contains($0.key) }
        save(filtered)
    }

    private func entries() -> [String: Entry] {
        guard let data = defaults.data(forKey: Self.storageKey),
              let entries = try? JSONDecoder().decode([String: Entry].self, from: data) else {
            return [:]
        }

        return entries
    }

    private func save(_ entries: [String: Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
