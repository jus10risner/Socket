//
//  MaintenanceAlertSettingsView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct MaintenanceAlertSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
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
                        await AppSettings.openSocketSettings()
                    }
                }
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MaintenanceAlertSettingsView()
        .environmentObject(AppSettings())
}
