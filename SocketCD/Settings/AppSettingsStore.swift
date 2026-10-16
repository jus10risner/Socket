//
//  AppSettingsStore.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

class AppSettingsStore: ObservableObject {
    
    static let shared = AppSettingsStore()

    // MARK: - AppSettingsView
    
    @AppStorage("distanceUnit") var distanceUnit: DistanceUnits = .miles {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("fuelEconomyUnit") var fuelEconomyUnit: FuelEconomyUnits = .mpg {
        willSet { objectWillChange.send() }
    }

    @AppStorage("volumeUnit") var volumeUnit: VolumeUnits = .usGallons {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("fillupCostType") var fillupCostType: FillupCostTypes = .total {
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

    @AppStorage("odometerReminderEnabled") var odometerReminderEnabled: Bool = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("odometerReminderIntervalDays") var odometerReminderIntervalDays: Int = 14 {
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

    init() {
        let defaults = UserDefaults.standard
        preserveLegacyFuelCostDefaultIfNeeded(in: defaults)

        let hasExistingUnitPreferences = defaults.object(forKey: "distanceUnit") != nil
            || defaults.object(forKey: "fuelEconomyUnit") != nil
            || defaults.object(forKey: "volumeUnit") != nil

        if !hasExistingUnitPreferences {
            applyRegionalUnitDefaults()
        } else if defaults.object(forKey: "volumeUnit") == nil {
            switch fuelEconomyUnit {
            case .mpg, .kmGal:
                volumeUnit = .usGallons
            case .mpgImperial:
                volumeUnit = .imperialGallons
            case .kmL, .L100km:
                volumeUnit = .liters
            }
        }
    }

    private func preserveLegacyFuelCostDefaultIfNeeded(in defaults: UserDefaults) {
        guard defaults.object(forKey: "fillupCostType") == nil else { return }

        let completedOnboarding = defaults.bool(forKey: "welcomeViewPresented") == false
            && defaults.object(forKey: "welcomeViewPresented") != nil
        let hasSavedAppVersion = defaults.string(forKey: "savedAppVersion")?.isEmpty == false

        if completedOnboarding || hasSavedAppVersion {
            defaults.set(FillupCostTypes.perUnit.rawValue, forKey: "fillupCostType")
        }
    }

    private func applyRegionalUnitDefaults(locale: Locale = .current) {
        switch locale.region?.identifier {
        case "US":
            distanceUnit = .miles
            volumeUnit = .usGallons
            fuelEconomyUnit = .mpg
        case "GB", "UK":
            distanceUnit = .miles
            volumeUnit = .liters
            fuelEconomyUnit = .mpgImperial
        default:
            distanceUnit = .kilometers
            volumeUnit = .liters
            fuelEconomyUnit = .L100km
        }
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
        }
    }
    
    // Opens the Settings app and navigates to Socket's system settings (camera access, etc.)
    static func openSocketSettings() async {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            await UIApplication.shared.open(url)
        }
    }
}
