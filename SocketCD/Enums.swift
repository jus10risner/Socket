//
//  Enums.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

// MARK: - VehicleDashboardView

enum AppSection: String, CaseIterable {
    case maintenance, repairs, fillups
}

// MARK: - Fill-ups

enum FillupCostTypes: String, CaseIterable {
    case perUnit, total
}

enum FillType: String, CaseIterable {
    case fullTank = "Full Tank", partialFill = "Partial Fill", missedFill = "Missed Fill-up"
}

enum DateRange: String, CaseIterable {
    case sixMonths = "6M", year = "1Y", all = "ALL"
    
    var accessibilityLabel: String {
        switch self {
        case .sixMonths:
            return "Last 6 months"
        case .year:
            return "Last year"
        case .all:
            return "All Time"
        }
    }
}


// MARK: - Services

enum ServiceStatus: Int {
    case notDue, due, overDue
}


// MARK: - Settings

enum AppearanceOptions: String, CaseIterable {
    case automatic, light, dark
}

enum AccentColors: String, CaseIterable {
    case red = "red", orange = "orange", yellow = "yellow", green = "green", blue = "blue", purple = "purple", cyan = "cyan", mint = "mint"
    
    // Returns the Color for the user's selected accent color
    var value: Color {
        switch self {
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
}

enum DistanceUnits: String, CaseIterable {
    case miles = "miles", kilometers = "kilometers"
    
    // Returns an abbreviated string for the user's selected distance units
    var abbreviated: String {
        switch self {
        case .miles:
            return "mi"
        default: 
            return "km"
        }
    }
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
    
    var fullName: String {
        switch self {
        case .mpg: 
            return "Miles per Gallon"
        case .kmL: 
            return "Kilometers per Liter"
        case .L100km: 
            return "Liters per 100km"
        }
    }
}

enum AppIcon: String, CaseIterable {
    case monochrome = "Monochrome", classicPurple = "Classic Purple", classicMonochrome = "Classic Monochrome"
}
