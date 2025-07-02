//
//  Enums.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

// MARK: - Add Vehicle View

enum FocusedField {
    case vehicleName, vehicleOdometer
}

// MARK: - TabView

// Returns both tags and tint colors for each tab
enum SelectedTab: Int {
    case maintenance = 0
    case repairs = 1
    case fillups = 2
    case vehicleInfo = 3
    
    func color() -> Color {
        switch self {
        case .maintenance:
            return Color.selectedColor(for: .maintenanceTheme)
        case .repairs:
            return Color.selectedColor(for: .repairsTheme)
        case .fillups:
            return Color.selectedColor(for: .fillupsTheme)
        case .vehicleInfo:
            return Color.selectedColor(for: .appTheme)
        }
    }
}

// MARK: - Fill-ups

enum FillupCostTypes: String, CaseIterable {
    case perUnit, total
}

enum FillType: String, CaseIterable {
    case fullTank = "Full Tank", partialFill = "Partial Fill", missedFill = "Missed Fill-up"
}

enum DateRange: String, CaseIterable {
    case threeMonths = "3M", sixMonths = "6M", year = "1Y", all = "ALL"
}


// MARK: - Services

enum ServiceIntervalTypes: String, CaseIterable {
    case distance = "Distance", time = "Time", both = "Both"
}

enum ServiceStatus: Int {
    case notDue, due, overDue
}


// MARK: - Settings

enum AppearanceOptions: String, CaseIterable {
    case automatic, light, dark
}

enum AvailableThemes {
    case appTheme, maintenanceTheme, repairsTheme, fillupsTheme
}

enum AccentColors: String, CaseIterable {
    case red = "red", orange = "orange", yellow = "yellow", green = "green", blue = "blue", indigo = "indigo", purple = "purple", cyan = "cyan", mint = "mint"
}

enum DistanceUnits: String, CaseIterable {
    case miles = "miles", kilometers = "kilometers"
}

enum FuelEconomyUnits: String, CaseIterable {
    case mpg = "mpg", kmL = "km/L", L100km = "L/100km"
}

enum AvailableAppIcons: String, CaseIterable {
    case dark = "Dark", light = "Light", darkMonochrome = "Dark Monochrome", lightMonochrome = "Light Monochrome"
}
