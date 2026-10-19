//
//  DashboardCustomization.swift
//  SocketCD
//

import SwiftUI

struct DashboardSectionPreference: Codable, Equatable, Identifiable {
    let section: AppSection
    var isVisible: Bool

    var id: AppSection { section }
}

extension Array where Element == DashboardSectionPreference {
    static var dashboardDefaults: Self {
        AppSection.allCases.map {
            DashboardSectionPreference(section: $0, isVisible: true)
        }
    }
}

struct DashboardLayoutStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(for vehicleID: UUID?) -> [DashboardSectionPreference] {
        guard
            let vehicleID,
            let data = defaults.data(forKey: key(for: vehicleID)),
            let storedPreferences = try? JSONDecoder().decode([DashboardSectionPreference].self, from: data)
        else {
            return .dashboardDefaults
        }

        var seenSections = Set<AppSection>()
        var preferences = storedPreferences.filter { seenSections.insert($0.section).inserted }

        for section in AppSection.allCases where !seenSections.contains(section) {
            preferences.append(DashboardSectionPreference(section: section, isVisible: true))
        }

        return preferences
    }

    func save(_ preferences: [DashboardSectionPreference], for vehicleID: UUID?) {
        guard
            let vehicleID,
            let data = try? JSONEncoder().encode(preferences)
        else {
            return
        }

        defaults.set(data, forKey: key(for: vehicleID))
    }

    private func key(for vehicleID: UUID) -> String {
        "dashboard.sections.\(vehicleID.uuidString)"
    }
}

struct DashboardCustomizationView: View {
    @Binding var preferences: [DashboardSectionPreference]

    let vehicleID: UUID?
    private let store = DashboardLayoutStore()

    var body: some View {
        List {
            Section {
                ForEach($preferences) { $preference in
                    Button {
                        preference.isVisible.toggle()
                    } label: {
                        Label {
                            Text(preference.section.title)
                        } icon: {
                            if preference.isVisible {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.white, Color.accent)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(preference.isVisible ? "Shown" : "Hidden")
                }
                .onMove { source, destination in
                    preferences.move(fromOffsets: source, toOffset: destination)
                }
            } footer: {
                Text("Choose which cards appear and drag them into your preferred order.")
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Edit Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: preferences) { _, newPreferences in
            store.save(newPreferences, for: vehicleID)
        }
    }
}
