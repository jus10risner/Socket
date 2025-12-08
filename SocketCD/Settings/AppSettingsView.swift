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
                    NavigationLink(destination: FuelCostSettingsView()) {
                        rowLabel(title: "Fuel Cost", symbol: "fuelpump")
                    }
                    
                    NavigationLink(destination: MaintenanceAlertSettingsView()) {
                        rowLabel(title: "Maintenance Alerts", symbol: "clock")
                    }
                    
                    NavigationLink(destination: UnitsOfMeasureSettingsView()) {
                        rowLabel(title: "Units of Measure", symbol: "ruler")
                    }
                }
                
                Section("Appearance") {
                    NavigationLink(destination: AccentColorSelectorView()) {
                        rowLabel(title: "Accent Color", symbol: "paintbrush")
                    }
                    
                    NavigationLink(destination: AppIconSelectorView()) {
                        rowLabel(title: "App Icon", symbol: "app.badge")
                    }
                    
                    NavigationLink(destination: appearanceSettings) {
                        rowLabel(title: "Appearance", symbol: "circle.lefthalf.filled")
                    }
                    
                    NavigationLink(destination: vehicleListSettings) {
                        rowLabel(title: "Vehicle List Style", symbol: "rectangle.grid.1x2")
                    }
                }
                
                Section {
                    contactButton
                    
                    Link(destination: URL(string: "https://apps.apple.com/us/app/socket-car-care-tracker/id6502462009?action=write-review")!, label: {
                        rowLabel(title: "Rate on the App Store", symbol: "star")
                    })
                    
                    ShareLink(item: appStoreURL) {
                        rowLabel(title: "Share Socket", symbol: "square.and.arrow.up")
                    }
                } header: {
                    Text("More")
                } footer: {
                    Text("Version \(AppInfo().version)")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done", systemImage: "xmark") { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
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
    
    // Navigates to App Theme settings
    private var appearanceSettings: some View {
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
    }
    
    private var vehicleListSettings: some View {
        List {
            Section(footer: Text("Choose how cards appear in the Vehicles list.")) {
                Picker("Vehicle List Style", selection: Binding(
                    get: { settings.vehicleListShouldBeCompact },
                    set: { settings.vehicleListIsCompact = $0 }
                )) {
                    Text("Compact")
                        .tag(true)
                    
                    Text("Regular")
                        .tag(false)
                }
                .labelsHidden()
            }
        }
        .navigationTitle("Vehicle List Style")
        .navigationBarTitleDisplayMode(.inline)
        .pickerStyle(.inline)
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
            rowLabel(title: "Contact", symbol: "envelope")
        }
    }
    
    // Styling for list row labels
    private func rowLabel(title: String, symbol: String) -> some View {
        Label {
            Text(title)
                .foregroundStyle(Color.primary)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(settings.selectedAccent())
        }

    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
}
