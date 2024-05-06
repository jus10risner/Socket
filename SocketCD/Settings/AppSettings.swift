//
//  AppSettings.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

class AppSettings: ObservableObject {
    
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
    
    @AppStorage("distanceBeforeMaintenance") var distanceBeforeMaintenance: Int = 500 {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("daysBeforeMaintenance") var daysBeforeMaintenance: Int = 14 {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("accentColor") var accentColor: AccentColors? {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("appIcon") var appIcon: AvailableAppIcons? {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("appAppearance") var appAppearance: AppearanceOptions = .automatic {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("notificationPermissionRequested") var notificationPermissionRequested: Bool = false {
        willSet { objectWillChange.send() }
    }
    
    
    // MARK: - Onboarding & What's New
    
    // Shows WelcomeView immediately on first launch of app; toggles to false on dismiss
    @AppStorage("welcomeViewPresented") var welcomeViewPresented: Bool = true
    
    // Toggles to true when QuickFillTip has been shown
    @AppStorage("quickFillTipPresented") var quickFillTipPresented: Bool = false
    
    // Used to determine whether the user has launched the app since the most recent update was released
    @AppStorage("savedAppVersion") var savedAppVersion: String = ""
    
    
    // MARK: - Helpers
    
    // Abbreviation of distance units
    var shortenedDistanceUnit: String {
        switch distanceUnit {
        case .miles:
            "mi"
        case .kilometers:
            "km"
        }
    }
    
    // Converts AccentColors Strings (from AppSettings) into Color values
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
        case .indigo:
            Color.indigo
        case .purple:
            Color.purple
        case .cyan:
            Color.cyan
        case .mint:
            Color.mint
        }
    }
}
