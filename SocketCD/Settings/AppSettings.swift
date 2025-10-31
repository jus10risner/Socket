//
//  AppSettings.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

class AppSettings: ObservableObject {
    
    static let shared = AppSettings()
    
    // MARK: - AppSettingsView
    
    @AppStorage("distanceUnit") var distanceUnit: DistanceUnits = .miles
    
    @AppStorage("fuelEconomyUnit") var fuelEconomyUnit: FuelEconomyUnits = .mpg
    
    @AppStorage("fillupCostType") var fillupCostType: FillupCostTypes = .perUnit
    
    @AppStorage("showCalculatedCost") var showCalculatedCost: Bool = false // Determines whether to show total or per-unit cost alongside the fillupCostType preference
    
    @AppStorage("distanceBeforeMaintenance") var distanceBeforeMaintenance: Int = 500
    
    @AppStorage("daysBeforeMaintenance") var daysBeforeMaintenance: Int = 14
    
    @AppStorage("accentColor") var accentColor: AccentColors?
    
    @AppStorage("appAppearance") var appAppearance: AppearanceOptions = .automatic
    
    
    // MARK: - Onboarding & What's New
    
    // Shows WelcomeView immediately on first launch of app; toggles to false on dismiss
    @AppStorage("welcomeViewPresented") var welcomeViewPresented: Bool = true
    
    // Toggles to true when OnboardingTips has been shown
    @AppStorage("onboardingTipsPresented") var onboardingTipsAlreadyPresented: Bool = false
    
    // Used to determine whether the user has launched the app since the most recent update was released
    @AppStorage("savedAppVersion") var savedAppVersion: String = ""
    
    
    // MARK: - Helpers
    
    func selectedAccent() -> Color {
        if let accentColor {
            return accentColor.value
        } else {
            return Color.indigo.mix(with: .cyan, by: 0.2) // Same as Color.accent (keeping here for mix reference)
        }
    }
    
    // Converts AccentColors Strings into Color values; used for the accent color selector in AppSettings
    func colorValue(for accentColor: AccentColors) -> Color {
        switch accentColor {
        case .red:
            Color.red
        case .orange:
            Color.orange
        case .yellow:
            Color.yellow
        case .green:
            Color.green
        case .blue:
            Color.blue
        case .purple:
            Color.purple
        case .cyan:
            Color.cyan
        case .mint:
            Color.mint
        }
    }
    
    // Opens the Settings app and navigates to Socket's system settings (camera access, etc.)
    static func openSocketSettings() async {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            await UIApplication.shared.open(url)
        }
    }
}
