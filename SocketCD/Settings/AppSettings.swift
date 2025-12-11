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
    
    @AppStorage("distanceUnit") var distanceUnit: DistanceUnits = .miles {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("fuelEconomyUnit") var fuelEconomyUnit: FuelEconomyUnits = .mpg {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("fillupCostType") var fillupCostType: FillupCostTypes = .perUnit {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("showCalculatedCost") var showCalculatedCost: Bool = false { // Determines whether to show total or per-unit cost alongside the fillupCostType preference
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("distanceBeforeMaintenance") var distanceBeforeMaintenance: Int = 500 {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("daysBeforeMaintenance") var daysBeforeMaintenance: Int = 14 {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("accentColor") var accentColor: AccentColors? {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("appAppearance") var appAppearance: AppearanceOptions = .automatic {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("vehicleListIsCompact") var vehicleListIsCompact: Bool? {
        willSet { objectWillChange.send() }
    }
    
    // Used to set the default vehicleCardIsCompact value to true for iPad and false for iPhone (for different default styles)
    var vehicleListShouldBeCompact: Bool {
        vehicleListIsCompact ?? (UIDevice.current.userInterfaceIdiom == .pad)
    }
    
    
    // MARK: - Onboarding & What's New
    
    // Shows WelcomeView immediately on first launch of app; toggles to false on dismiss
    @AppStorage("welcomeViewPresented") var welcomeViewShouldPresent: Bool = true
    
    // Used to determine whether the user has agreed to the terms of use
    @AppStorage("termsOfUseAccepted") var termsOfUseAccepted: Bool = false
    
    // Used to determine whether the user has launched the app since the most recent update was released
    @AppStorage("savedAppVersion") var savedAppVersion: String = ""
    
    
    // MARK: - Helpers
    
    // Returns either the user's selected accent color, or the default accent color
    func selectedAccent() -> Color {
        if let accentColor {
            return accentColor.value
        } else {
            return Color.accent
//            Color.indigo.mix(with: .cyan, by: 0.2) (keeping here for mix reference)
        }
    }
    
    // Opens the Settings app and navigates to Socket's system settings (camera access, etc.)
    static func openSocketSettings() async {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            await UIApplication.shared.open(url)
        }
    }
}
