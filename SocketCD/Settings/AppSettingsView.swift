//
//  AppSettingsView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State var showingMailError = false
    
    var body: some View {
        settingsView
    }
    
    
    // MARK: - Views
    
    private var settingsView: some View {
        AppropriateNavigationType {
            VStack {
                Form {
                    Section("General") {
                        maintenanceAlertsSettingsButton
                        
                        fuelCostSettingsButton
                        
                        unitsOfMeasureSettingsButton
                    }
                    
                    Section("Appearance") {
                        accentColorSettingsButton
                        
                        appIconSettingsButton
                        
                        themeSettingsButton
                    }
                    
                    Section("Data") {
                        iCloudSyncSettingsbutton
                    }
                    
                    Section("More") {
                        contactButton
                        
                        rateButton
                        
                        shareAppButton
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                
                Text("Version \(AppInfo().version)")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.bottom, 10)
            }
            .background(Color(.systemGroupedBackground))
        }
        .conditionalTint(.selectedColor(for: .appTheme))
        .alert("Could not send mail", isPresented: $showingMailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\nPlease make sure email has been set up on this device, then try again.")
        }
    }
    
    // Navigates to Alerts settings
    private var maintenanceAlertsSettingsButton: some View {
        NavigationLink {
            MaintenanceAlertSettingsView()
        } label: {
            Label("Alerts", systemImage: "clock")
        }
    }
    
    // Navigates to Fuel Cost settings
    private var fuelCostSettingsButton: some View {
        NavigationLink {
            List {
                Section(footer: Text("Choose how you prefer to enter fuel costs, when logging fill-ups.")) {
                    Picker("Fill-up Cost Type", selection: $settings.fillupCostType) {
                        ForEach(FillupCostTypes.allCases, id: \.self) { type in
                            if type == .perUnit {
                                if settings.fuelEconomyUnit == .mpg {
                                    Text("Price per gallon")
                                } else {
                                    Text("Price per liter")
                                }
                            } else {
                                Text("Total cost")
                            }
                        }
                    }
                    .labelsHidden()
                }
            }
            .navigationTitle("Fuel Cost")
            .navigationBarTitleDisplayMode(.inline)
            .pickerStyle(.inline)
        } label: {
            Label("Fuel Cost", systemImage: "fuelpump")
        }
    }
    
    // Navigates to Units of Measure settings
    private var unitsOfMeasureSettingsButton: some View {
        NavigationLink {
            List {
                Picker("Distance", selection: $settings.distanceUnit) {
                    ForEach(DistanceUnits.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                
                Picker("Fuel Economy", selection: $settings.fuelEconomyUnit) {
                    ForEach(FuelEconomyUnits.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
            }
            .navigationTitle("Units of Measure")
            .navigationBarTitleDisplayMode(.inline)
            .pickerStyle(.inline)
        } label: {
            Label("Units of Measure", systemImage: "ruler")
        }
    }
    
    // Allows user to toggle iCloud sync on/off
    private var iCloudSyncSettingsbutton: some View {
        NavigationLink {
            List {
                Section {
                    Toggle(isOn: $settings.iCloudSyncEnabled, label: {
                        Text("Use iCloud")
                    })
                } footer: {
                    Text("Toggle on to sync Socket's data to your iCloud account.")
                }
            }
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Label("iCloud Sync", systemImage: "arrow.triangle.2.circlepath.icloud")
        }
    }
    
    // Navigates to Accent Color settings
    private var accentColorSettingsButton: some View {
        NavigationLink {
            Form {
                AccentColorSelectorView()
            }
            .navigationTitle("Accent Color")
        } label: {
            Label("Accent Color", systemImage: "paintpalette")
        }
    }
    
    // Navigates to App Icon settings
    private var appIconSettingsButton: some View {
        NavigationLink {
            AppIconSelectorView()
        } label: {
            Label("App Icon", systemImage: "app")
        }
    }
    
    // Navigates to App Theme settings
    private var themeSettingsButton: some View {
        NavigationLink {
            List {
                Section(footer: Text("The color scheme used across the entire app.")) {
                    Picker("App Theme", selection: $settings.appAppearance) {
                        ForEach(AppearanceOptions.allCases, id: \.self) {
                            Text($0.rawValue.capitalized)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: settings.appAppearance) { _ in
                        AppearanceController.shared.setAppearance()
//                        try? context.save()
                    }
                }
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .pickerStyle(.inline)
        } label: {
            Label("Theme", systemImage: "circle.lefthalf.filled")
        }
    }
    
    // Launches Mail Composer, if email has been set up
    private var contactButton: some View {
        Button {
            let composeVC = MailComposeViewController.shared
            
            if composeVC.canSendEmail == true {
                // Composes an email message, and prefills Socket's address
                composeVC.sendEmail()
            } else {
                showingMailError = true
            }
        } label: {
            Label("Contact", systemImage: "envelope")
        }
    }
    
    // Shares a link to Socket on the App Store
    private var shareAppButton: some View {
        Button {
            // TODO: Add this link
            // App Store link will be added here, when app is approved
        } label: {
            Label("Share Socket", systemImage: "square.and.arrow.up")
        }
    }
    
    // Navigates to "Write a Review" for Socket, in the App Store
    private var rateButton: some View {
        Button {
            // TODO: Add this link
            // Link to App Store's "Write a Review" sheet
        } label: {
            Label("Rate Socket", systemImage: "star")
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
}
