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
    
    @State private var distanceBeforeMaintenance = Int("")
    @State private var daysBeforeMaintenance = Int("")
    
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
        .onAppear {
            distanceBeforeMaintenance = settings.distanceBeforeMaintenance
            daysBeforeMaintenance = settings.daysBeforeMaintenance
        }
        .onDisappear {
            settings.distanceBeforeMaintenance = distanceBeforeMaintenance ?? 500
            settings.daysBeforeMaintenance = daysBeforeMaintenance ?? 14
        }
    }
    
    
    // MARK: - Views
    
    // TextField to specify how many mi/km before maintenance is due that the user would like to be notified
    private var distanceBeforeDueField: some View {
        HStack {
            Text("\(settings.distanceUnit.rawValue.capitalized) before due")
            
            Spacer()
            
            TextField("\(settings.distanceUnit.rawValue.capitalized)", value: $distanceBeforeMaintenance, format: .number.decimalSeparator(strategy: .automatic))
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
            
            TextField("Days", value: $daysBeforeMaintenance, format: .number.decimalSeparator(strategy: .automatic))
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
                await openSocketSettings()
            }
        }
    }
    
    // MARK: - Methods
    
    @MainActor
    func openSocketSettings() async {
        // Creates URL that links to Socket settings in the Settings app
        if let url = URL(string: UIApplication.openSettingsURLString) {
            
            // Takes the user to Socket settings
            await UIApplication.shared.open(url)
        }
    }
}

#Preview {
    MaintenanceAlertSettingsView()
        .environmentObject(AppSettings())
}
