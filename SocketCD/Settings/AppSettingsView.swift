//
//  AppSettingsView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var settings: AppSettingsStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    let appStoreURL: URL = URL(string: "https://apps.apple.com/us/app/socket-car-care-tracker/id6502462009")!
    
    @State private var showingEmailCopied = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    NavigationLink(destination: FuelCostSettingsView()) {
                        rowLabel(title: "Fuel Cost", symbol: "fuelpump")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        rowLabel(title: "Notifications", symbol: "app.badge")
                    }
                    
                }
                
                Section("Styling") {
                    NavigationLink(destination: AccentColorSelectorView()) {
                        rowLabel(title: "Accent Color", symbol: "paintbrush")
                    }
                    
                    NavigationLink(destination: AppIconSelectorView()) {
                        rowLabel(title: "App Icon", symbol: "app")
                    }
                    
                    NavigationLink(destination: appearanceSettings) {
                        rowLabel(title: "Appearance", symbol: "circle.lefthalf.filled")
                    }
                    
                    NavigationLink(destination: vehicleListSettings) {
                        rowLabel(title: "Vehicle List Style", symbol: "rectangle.grid.1x2")
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://apps.apple.com/us/app/socket-car-care-tracker/id6502462009?action=write-review")!, label: {
                        rowLabel(title: "Rate on the App Store", symbol: "star")
                    })
                    
                    sendFeedbackButton
                    
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
            .alert("We’d Love Your Feedback", isPresented: $showingEmailCopied) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn’t open a new email, so we copied our address to your clipboard. To send us feedback, paste it into the To field of a new message in your usual email app or website.")
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
    private var sendFeedbackButton: some View {
        Button {
            let composeVC = MailComposeViewController.shared
            
            if !composeVC.sendEmail() {
                openFeedbackEmail()
            }
        } label: {
            rowLabel(title: "Send Feedback", symbol: "envelope")
        }
    }
    
    private func openFeedbackEmail() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = MailComposeViewController.feedbackEmailAddress
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Socket Feedback")
        ]

        guard let url = components.url else {
            copyFeedbackEmail()
            return
        }

        // This result reports whether the URL opened, not whether an email was sent.
        openURL(url) { accepted in
            if !accepted {
                copyFeedbackEmail()
            }
        }
    }

    private func copyFeedbackEmail() {
        UIPasteboard.general.string = MailComposeViewController.feedbackEmailAddress
        showingEmailCopied = true
    }

    // Styling for list row labels
    private func rowLabel(title: String, symbol: String) -> some View {
        Label {
            Text(title)
                .foregroundStyle(Color.primary)
        } icon: {
            Image(systemName: symbol)
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettingsStore())
}
