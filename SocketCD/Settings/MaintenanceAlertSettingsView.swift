//
//  MaintenanceAlertSettingsView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct MaintenanceAlertSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    @FocusState var isInputActive: Bool
    
    var body: some View {
        List {
            Section(footer: Text("Specifies how far in advance Socket should alert you of upcoming maintenance services.")) {
                distanceBeforeDueField
                
                daysBeforeDueField
            }
            
            Section(footer: Text("Navigates to the Settings app, where you can make changes to Socket's notification preferences.")) {
                socketSettingsButton
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    // MARK: - Views
    
    // TextField to specify how many mi/km before maintenance is due that the user would like to be notified
    private var distanceBeforeDueField: some View {
        HStack {
            Text("\(settings.distanceUnit.rawValue.capitalized) before due")
            
            Spacer()
            
            TextField("\(settings.distanceUnit.rawValue.capitalized)", value: $settings.distanceBeforeMaintenance, format: .number.decimalSeparator(strategy: .automatic))
                .keyboardType(.numberPad)
                .fixedSize()
                .textFieldStyle(.roundedBorder)
                .focused($isInputActive)
        }
    }
    
    // TextField to specify how many days before maintenance is due that the user would like to be notified
    private var daysBeforeDueField: some View {
        HStack {
            Text("Days before due")
            
            Spacer()
            
            TextField("Days", value: $settings.daysBeforeMaintenance, format: .number.decimalSeparator(strategy: .automatic))
                .keyboardType(.numberPad)
                .fixedSize()
                .textFieldStyle(.roundedBorder)
                .focused($isInputActive)
        }
    }
    
    // Button that navigates to the Socket section of the iOS Settings app
    private var socketSettingsButton: some View {
        Button("Notification Settings") {
            Task {
                await AppSettings.openSocketSettings()
            }
        }
    }
}

#Preview {
    MaintenanceAlertSettingsView()
        .environmentObject(AppSettings())
}
