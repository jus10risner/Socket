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
                        Label {
                            Text("Maintenance Alerts")
                        } icon: {
                            Image(systemName: "clock")
                                .foregroundStyle(settings.accentColor(for: .appTheme))
                        }
                    }
                    
                    fuelCostSettingsButton
                    
                    unitsOfMeasureSettingsButton
                }
                
                Section("Appearance") {
                    NavigationLink(destination: AccentColorSelectorView()) {
                        Label {
                            Text("Accent Color")
                        } icon: {
                            Image(systemName: "paintbrush")
                                .foregroundStyle(settings.accentColor(for: .appTheme))
                        }
                    }
                    
                    NavigationLink(destination: AppIconSelectorView()) {
                        Label {
                            Text("App Icon")
                        } icon: {
                            Image(systemName: "app.badge")
                                .foregroundStyle(settings.accentColor(for: .appTheme))
                        }
                    }
                    
                    themeSettingsButton
                }
                
                Section("More") {
                    contactButton
                    
                    Link(destination: URL(string: "https://apps.apple.com/us/app/socket-car-care-tracker/id6502462009?action=write-review")!, label: {
                        Label {
                            Text("Rate on the App Store")
                        } icon: {
                            Image(systemName: "star")
                                .foregroundStyle(settings.accentColor(for: .appTheme))
                        }
                    })
                    
                    ShareLink(item: appStoreURL) {
                        Label {
                            Text("Share Socket")
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(settings.accentColor(for: .appTheme))
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Text("Version \(AppInfo().version)")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .listRowBackground(Color(.systemGroupedBackground))
                    .frame(maxWidth: .infinity)
            }
            .listItemTint(settings.accentColor(for: .appTheme))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
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
        .tint(settings.accentColor(for: .appTheme))
    }
    
    
    // MARK: - Views
    
    // Navigates to Fuel Cost settings
    private var fuelCostSettingsButton: some View {
        NavigationLink {
            List {
                Section(footer: Text("Choose how you prefer to enter fuel costs when logging fill-ups.")) {
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
                
                Section(footer: Text("Shows the \(settings.fillupCostType == .total ? "per-\(settings.fuelEconomyUnit.volumeUnit.lowercased())" : "total") cost, calculated from your input, when logging a fill-up.")) {
                    Toggle("Verify Cost", isOn: $settings.showCalculatedCost)
                }
            }
            .navigationTitle("Fuel Cost")
            .navigationBarTitleDisplayMode(.inline)
            .pickerStyle(.inline)
        } label: {
            Label {
                Text("Fuel Cost")
            } icon: {
                Image(systemName: "fuelpump")
                    .foregroundStyle(settings.accentColor(for: .appTheme))
            }
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
            Label {
                Text("Units of Measure")
            } icon: {
                Image(systemName: "ruler")
                    .foregroundStyle(settings.accentColor(for: .appTheme))
            }
        }
    }
    
    // Navigates to App Theme settings
    private var themeSettingsButton: some View {
        NavigationLink {
            List {
                Section(footer: Text("Switch between light and dark, or follow your device.")) {
                    Picker("Appearance Selection", selection: $settings.appAppearance) {
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
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .pickerStyle(.inline)
        } label: {
            Label {
                Text("Appearance")
            } icon: {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(settings.accentColor(for: .appTheme))
            }
        }
    }
    
    // Launches Mail Composer, if email has been set up
    private var contactButton: some View {
        Button {
            let composeVC = MailComposeViewController.shared
            
            if composeVC.canSendEmail {
                composeVC.sendEmail() // Composes an email message and prefills Socket's address
            } else {
                showingMailError = true
            }
        } label: {
            Label {
                Text("Contact")
            } icon: {
                Image(systemName: "envelope")
                    .foregroundStyle(settings.accentColor(for: .appTheme))
            }
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
}
