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
    let appStoreURL: URL = URL(string: "https://apps.apple.com/us/app/socket-car-care-tracker/id6502462009")!
    
    @State private var showingMailError = false
    @State private var showingActivityView = false
    
    var body: some View {
        settingsView
    }
    
    
    // MARK: - Views
    
    private var settingsView: some View {
        AppropriateNavigationType {
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
                
                Section("More") {
                    contactButton
                    
                    rateButton
                    
                    shareAppButton
                }
                .buttonStyle(.plain)
                
                Text("Version \(AppInfo().version)")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .listRowBackground(Color(.systemGroupedBackground))
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingActivityView) { ActivityView(activityItems: [appStoreURL as Any], applicationActivities: nil) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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
    
    // Navigates to Accent Color settings
    private var accentColorSettingsButton: some View {
        NavigationLink {
            Form {
                AccentColorSelectorView()
            }
            .navigationTitle("Accent Color")
        } label: {
            Label("Accent Color", systemImage: "paintbrush")
        }
    }
    
    // Navigates to App Icon settings
    private var appIconSettingsButton: some View {
        NavigationLink {
            AppIconSelectorView()
        } label: {
            Label("App Icon", systemImage: "app.badge")
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
    
    // Navigates to "Write a Review" for Socket, in the App Store
    private var rateButton: some View {
        Link(destination: URL(string: "https://apps.apple.com/us/app/socket-car-care-tracker/id6502462009?action=write-review")!, label: {
            Label("Rate on the App Store", systemImage: "star")
        })
    }
    
    // Shares a link to Socket on the App Store
    private var shareAppButton: some View {
        Group {
            if #available(iOS 16, *) {
                ShareLink(item: appStoreURL) {
                    Label("Share Socket", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    showingActivityView = true
                } label: {
                    Label("Share Socket", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
}
