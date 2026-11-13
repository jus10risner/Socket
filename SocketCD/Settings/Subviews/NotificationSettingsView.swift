//
//  NotificationSettingsView.swift
//  SocketCD
//

import SwiftUI

private enum Field: Hashable {
    case distanceAlert, daysAlert, odometerAlert
}

struct NotificationSettingsView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @FocusState private var focusedField: Field?

    var body: some View {
        List {
            MaintenanceDueAlertsSection(
                distanceBeforeMaintenance: $settings.distanceBeforeMaintenance,
                daysBeforeMaintenance: $settings.daysBeforeMaintenance,
                focusedField: $focusedField
            )

            OdometerUpdatesSection(
                isEnabled: $settings.odometerReminderEnabled,
                intervalDays: $settings.odometerReminderIntervalDays,
                focusedField: $focusedField
            )

            IOSNotificationSettingsSection()

#if DEBUG
            NotificationTestingSection()
#endif
        }
        .keyboardToolbar(
            isFocused: focusedField != nil,
            canMovePrevious: focusedField != .distanceAlert,
            canMoveNext: focusedField == .distanceAlert ||
                (focusedField == .daysAlert && settings.odometerReminderEnabled),
            onPrevious: focusPreviousField,
            onNext: focusNextField,
            onDone: { focusedField = nil }
        )
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: settings.distanceBeforeMaintenance) {
            refreshNotifications()
        }
        .onChange(of: settings.daysBeforeMaintenance) {
            refreshNotifications()
        }
        .onChange(of: settings.odometerReminderEnabled) { wasEnabled, isEnabled in
            if !isEnabled && focusedField == .odometerAlert {
                focusedField = .daysAlert
            }
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

    private func focusPreviousField() {
        switch focusedField {
        case .daysAlert:
            focusedField = .distanceAlert
        case .odometerAlert:
            focusedField = .daysAlert
        default:
            break
        }
    }

    private func focusNextField() {
        switch focusedField {
        case .distanceAlert:
            focusedField = .daysAlert
        case .daysAlert where settings.odometerReminderEnabled:
            focusedField = .odometerAlert
        default:
            break
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
    @FocusState.Binding var focusedField: Field?

    var body: some View {
        Section {
            LabeledContent("Distance before due") {
                NumericInput("Distance", value: $distanceBeforeMaintenance, focus: $focusedField, field: .distanceAlert)
                    .fontWeight(.medium)
            }
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .distanceAlert }
            
            LabeledContent("Days before due") {
                NumericInput("Days", value: $daysBeforeMaintenance, focus: $focusedField, field: .daysAlert)
                    .fontWeight(.medium)
            }
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .daysAlert }
        } header: {
            Text("Service Reminders")
        } footer: {
            Text("Distance uses each vehicle’s selected units.")
        }
        .multilineTextAlignment(.trailing)
        .keyboardType(.numberPad)
    }
}

private struct OdometerUpdatesSection: View {
    @Binding var isEnabled: Bool
    @Binding var intervalDays: Int
    @FocusState.Binding var focusedField: Field?

    var body: some View {
        Section {
            Toggle(
                "Odometer Reminders",
                isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if !newValue && focusedField == .odometerAlert {
                            focusedField = .daysAlert
                        }

                        withAnimation {
                            isEnabled = newValue
                        }
                    }
                )
            )
            
            if isEnabled {
                LabeledContent("Reminder Interval (Days)") {
                    NumericInput("Days", value: $intervalDays, focus: $focusedField, field: .odometerAlert)
                        .fixedSize(horizontal: true, vertical: false)
                        .multilineTextAlignment(.trailing)
                        .fontWeight(.medium)
                }
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .odometerAlert }
            }
        } footer: {
            Text("Socket can remind you when your odometer hasn’t been updated recently.")
        }
        .onChange(of: focusedField == .odometerAlert) { _, isFocused in
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
                    Image(systemName: "arrow.up.forward")
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
