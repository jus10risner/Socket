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

// MARK: - VehicleDashboardView

enum AppSection: String, CaseIterable {
    case maintenance, repairs, fillups, vehicle
    
    var symbol: String {
        switch self {
        case .maintenance:
            return "book.and.wrench.fill"
        case .repairs:
            return "wrench.fill"
        case .fillups:
            return "fuelpump.fill"
        case .vehicle:
            return "car.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .maintenance:
            return Color.selectedColor(for: .maintenanceTheme)
        case .repairs:
            return Color.selectedColor(for: .repairsTheme)
        case .fillups:
            return Color.selectedColor(for: .fillupsTheme)
        case .vehicle:
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
    
    // Returns the fuel volume unit for the user's selected fuel economy units
    var volumeUnit: String {
        switch self {
        case .mpg: 
            return "Gallon"
        default: 
            return "Liter"
        }
    }
}

enum AvailableAppIcons: String, CaseIterable {
    case dark = "Dark", light = "Light", darkMonochrome = "Dark Monochrome", lightMonochrome = "Light Monochrome"
}
