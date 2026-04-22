//
//  MaintenanceAlertSettingsView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct MaintenanceAlertSettingsView: View {
    @EnvironmentObject var settings: AppSettingsStore
    
    // Track initial values for change detection
    @State private var initialDistanceBefore: Int = 0
    @State private var initialDaysBefore: Int = 0
    
    var body: some View {
        List {
            Section(footer: Text("When Socket should alert you of upcoming maintenance services")) {
                LabeledInput(label: "\(settings.distanceUnit.rawValue.capitalized) before due") {
                    TextField("\(settings.distanceUnit.rawValue.capitalized)", value: $settings.distanceBeforeMaintenance, format: .number.decimalSeparator(strategy: .automatic))
                        .keyboardType(.numberPad)
                }
                
                LabeledInput(label: "Days before due") {
                    TextField("Days", value: $settings.daysBeforeMaintenance, format: .number.decimalSeparator(strategy: .automatic))
                        .keyboardType(.numberPad)
                }
            }
            
            Section(footer: Text("Manage Socket’s notification preferences in the Settings app.")) {
                Button("Notification Settings") {
                    Task {
                        await AppSettingsStore.openSocketSettings()
                    }
                }
            }
        }
        .navigationTitle("Maintenance Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Capture initial values for comparison
            initialDistanceBefore = settings.distanceBeforeMaintenance
            initialDaysBefore = settings.daysBeforeMaintenance
        }
        .onDisappear {
            // Only reschedule if values actually changed
            let distanceChanged = settings.distanceBeforeMaintenance != initialDistanceBefore
            let daysChanged = settings.daysBeforeMaintenance != initialDaysBefore

            guard distanceChanged || daysChanged else { return }

            Task {
                await NotificationManager.shared.cancelAndRescheduleAllNotifications()
            }
        }
    }
}

#Preview {
    MaintenanceAlertSettingsView()
        .environmentObject(AppSettingsStore())
}
