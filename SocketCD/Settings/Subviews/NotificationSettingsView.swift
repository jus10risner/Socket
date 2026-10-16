//
//  NotificationSettingsView.swift
//  SocketCD
//

import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settings: AppSettingsStore

    var body: some View {
        List {
            MaintenanceDueAlertsSection(
                distanceBeforeMaintenance: $settings.distanceBeforeMaintenance,
                daysBeforeMaintenance: $settings.daysBeforeMaintenance
            )

            OdometerUpdatesSection(
                isEnabled: $settings.odometerReminderEnabled,
                intervalDays: $settings.odometerReminderIntervalDays
            )

            IOSNotificationSettingsSection()

#if DEBUG
            NotificationTestingSection()
#endif
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.distanceBeforeMaintenance) {
            refreshNotifications()
        }
        .onChange(of: settings.daysBeforeMaintenance) {
            refreshNotifications()
        }
        .onChange(of: settings.odometerReminderEnabled) { wasEnabled, isEnabled in
            if isEnabled && !wasEnabled {
                NotificationManager.shared.resetOdometerReminderBaseline()
            }
            refreshNotifications()
        }
        .onChange(of: settings.odometerReminderIntervalDays) { _, newValue in
            if newValue >= 1 {
                refreshNotifications()
            }
        }
    }

    private func refreshNotifications() {
        Task {
            await NotificationManager.shared.refreshAllNotifications()
        }
    }
}

private struct MaintenanceDueAlertsSection: View {
    @Binding var distanceBeforeMaintenance: Int
    @Binding var daysBeforeMaintenance: Int

    var body: some View {
        Section {
            LabeledContent("Distance before due") {
                TextField(
                    "Distance",
                    value: $distanceBeforeMaintenance,
                    format: .number.decimalSeparator(strategy: .automatic)
                )
                .multilineTextAlignment(.trailing)
                .fontWeight(.medium)
                .keyboardType(.numberPad)
            }
            
            LabeledContent("Days before due") {
                TextField(
                    "Days",
                    value: $daysBeforeMaintenance,
                    format: .number.decimalSeparator(strategy: .automatic)
                )
                .multilineTextAlignment(.trailing)
                .fontWeight(.medium)
                .keyboardType(.numberPad)
            }
        } header: {
            Text("Service Reminders")
        } footer: {
            Text("Distance uses each vehicle’s selected units.")
        }
    }
}

private struct OdometerUpdatesSection: View {
    @Binding var isEnabled: Bool
    @Binding var intervalDays: Int
    @FocusState private var intervalIsFocused: Bool

    var body: some View {
        Section {
            Toggle(
                "Odometer Reminders",
                isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if !newValue {
                            intervalIsFocused = false
                        }

                        withAnimation {
                            isEnabled = newValue
                        }
                    }
                )
            )
            
            if isEnabled {
                LabeledContent("Reminder Interval (Days)") {
                    TextField(
                        "Days",
                        value: $intervalDays,
                        format: .number
                    )
                    .fixedSize(horizontal: true, vertical: false)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.medium)
                    .keyboardType(.numberPad)
                    .focused($intervalIsFocused)
                }
            }
        } footer: {
            Text(
                "Socket can remind you when your odometer hasn’t been updated recently."
            )
        }
        .onChange(of: intervalIsFocused) { _, isFocused in
            if !isFocused {
                validateInterval()
            }
        }
        .onDisappear {
            validateInterval()
        }
    }

    private func validateInterval() {
        intervalDays = max(1, intervalDays)
    }
}

private struct IOSNotificationSettingsSection: View {
    var body: some View {
        Section(footer: Text("Opens the Settings app")) {
            Button {
                Task {
                    await AppSettingsStore.openSocketSettings()
                }
            } label: {
                LabeledContent {
                    Image(systemName: "arrow.up.forward.square")
                        .foregroundStyle(AppSettingsStore.shared.selectedAccent())
                } label: {
                    Text("Manage Notification Settings")
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
private struct NotificationTestingSection: View {
    @State private var errorMessage = ""
    @State private var isShowingError = false

    var body: some View {
        Section {
            Button("Send Test Notification") {
                Task {
                    do {
                        try await NotificationManager.shared.scheduleTestNotification()
                    } catch {
                        errorMessage = error.localizedDescription
                        isShowingError = true
                    }
                }
            }
        } header: {
            Text("Testing")
        } footer: {
            Text("Schedules a notification in 10 seconds. Leave Socket to see it.")
        }
        .alert("Unable to Schedule Test", isPresented: $isShowingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}
#endif

#Preview {
    NotificationSettingsView()
        .environmentObject(AppSettingsStore())
}
