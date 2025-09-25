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
    let appStoreURL: URL = URL(string: "https://apps.apple.com/us/app/socket-car-care-tracker/id6502462009")!
    
    @State private var showingMailError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    NavigationLink(destination: MaintenanceAlertSettingsView()) {
                        Label("Alerts", systemImage: "clock")
                    }
                    
                    fuelCostSettingsButton
                    
                    unitsOfMeasureSettingsButton
                }
                
                Section("Appearance") {
                    NavigationLink(destination: AccentColorSelectorView()) {
                        Label("Accent Color", systemImage: "paintbrush")
                    }
                    
                    NavigationLink(destination: AppIconSelectorView()) {
                        Label("App Icon", systemImage: "app.badge")
                    }
                    
                    themeSettingsButton
                }
                
                Section("More") {
                    contactButton
                    
                    Link(destination: URL(string: "https://apps.apple.com/us/app/socket-car-care-tracker/id6502462009?action=write-review")!, label: {
                        Label("Rate on the App Store", systemImage: "star")
                    })
                    
                    ShareLink(item: appStoreURL) {
                        Label("Share Socket", systemImage: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.plain)
                
                Text("Version \(AppInfo().version)")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .listRowBackground(Color(.systemGroupedBackground))
                    .frame(maxWidth: .infinity)
            }
            .tint(settings.accentColor(for: .appTheme))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "xmark") { dismiss() }
                        .labelStyle(.adaptive)
                }
            }
            .alert("Could not send mail", isPresented: $showingMailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please make sure email has been set up on this device, then try again.")
            }
        }
    }
    
    
    // MARK: - Views
    
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
                
                Section {
                    Toggle("Display both costs", isOn: $settings.showCalculatedCost)
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
                    .onChange(of: settings.appAppearance) {
                        AppearanceController.shared.setAppearance()
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
        Button("Contact", systemImage: "envelope") {
            let composeVC = MailComposeViewController.shared
            
            if composeVC.canSendEmail {
                composeVC.sendEmail() // Composes an email message and prefills Socket's address
            } else {
                showingMailError = true
            }
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
}
