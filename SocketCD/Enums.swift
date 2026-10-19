//
//  Enums.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

// MARK: - VehicleDashboardView

enum AppSection: String, CaseIterable, Codable, Identifiable {
    case maintenance, fillups, repairs, customInfo

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .maintenance: "Maintenance"
        case .fillups: "Fill-ups"
        case .repairs: "Repairs"
        case .customInfo: "Custom Info"
        }
    }

    func symbol(filled: Bool = false) -> String {
        switch (self, filled) {
        case (.maintenance, false): "book.and.wrench"
        case (.maintenance, true): "book.and.wrench.fill"
        case (.fillups, false): "fuelpump"
        case (.fillups, true): "fuelpump.fill"
        case (.repairs, false): "wrench.adjustable"
        case (.repairs, true): "wrench.adjustable.fill"
        case (.customInfo, false): "folder"
        case (.customInfo, true): "folder.fill"
        }
    }

    var color: Color {
        switch self {
        case .maintenance: .green
        case .fillups: .teal
        case .repairs: .orange
        case .customInfo: AppSettingsStore.shared.selectedAccent()
        }
    }
}

// MARK: - Fill-ups

enum FillupCostTypes: String, CaseIterable {
    case total, perUnit

    var title: LocalizedStringResource {
        switch self {
        case .total:
            "Total cost"
        case .perUnit:
            "Cost per unit"
        }
    }

    var verificationDescription: LocalizedStringResource {
        switch self {
        case .total:
            "Shows the per-unit cost, calculated from your input, when logging a fill-up."
        case .perUnit:
            "Shows the total cost, calculated from your input, when logging a fill-up."
        }
    }
}

enum FillType: String, CaseIterable {
    case fullTank = "Full Tank", partialFill = "Partial Fill", missedFill = "Missed Fill-up"
}

enum DateRange: String, CaseIterable {
    case threeMonths = "3M", sixMonths = "6M", year = "1Y"
    
    var accessibilityLabel: String {
        switch self {
        case .threeMonths:
            return "Three-month window"
        case .sixMonths:
            return "Six-month window"
        case .year:
            return "One-year window"
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

enum VolumeUnits: String, CaseIterable {
    case liters = "liters"
    case usGallons = "US gallons"
    case imperialGallons = "Imperial gallons"

    var abbreviated: String {
        switch self {
        case .liters: "L"
        case .usGallons, .imperialGallons: "gal"
        }
    }

    var singularName: String {
        switch self {
        case .liters: "Liter"
        case .usGallons, .imperialGallons: "Gallon"
        }
    }

    var exportAbbreviation: String {
        switch self {
        case .liters: "L"
        case .usGallons: "US gal"
        case .imperialGallons: "Imp gal"
        }
    }

    var settingsName: String {
        switch self {
        case .liters: "Liters"
        case .usGallons: "US Gallons"
        case .imperialGallons: "Imperial Gallons"
        }
    }
}

enum FuelEconomyUnits: String, CaseIterable {
    case mpg = "mpg"
    case mpgImperial = "mpg (UK)"
    case kmL = "km/L"
    case L100km = "L/100km"
    case kmGal = "km/gal"
    
    var fullName: String {
        switch self {
        case .mpg: "Miles per US Gallon"
        case .mpgImperial: "Miles per Imperial Gallon"
        case .kmL: "Kilometers per Liter"
        case .L100km: "Liters per 100 Kilometers"
        case .kmGal: "Kilometers per US Gallon"
        }
    }

    var displayName: String {
        switch self {
        case .mpg, .mpgImperial: "mpg"
        case .kmL: "km/L"
        case .L100km: "L/100km"
        case .kmGal: "km/gal"
        }
    }

    var settingsName: String {
        switch self {
        case .mpg: "MPG (US)"
        case .mpgImperial: "MPG (UK)"
        case .kmL, .L100km, .kmGal: displayName
        }
    }
}

enum MeasurementConverter {
    private static let kilometersPerMile = 1.609344
    private static let litersPerUSGallon = 3.785411784
    private static let litersPerImperialGallon = 4.54609

    static func kilometers(from value: Double, unit: DistanceUnits) -> Double {
        unit == .kilometers ? value : value * kilometersPerMile
    }

    static func distance(fromKilometers value: Double, unit: DistanceUnits) -> Double {
        unit == .kilometers ? value : value / kilometersPerMile
    }

    static func liters(from value: Double, unit: VolumeUnits) -> Double {
        switch unit {
        case .liters: value
        case .usGallons: value * litersPerUSGallon
        case .imperialGallons: value * litersPerImperialGallon
        }
    }

    static func volume(fromLiters value: Double, unit: VolumeUnits) -> Double {
        switch unit {
        case .liters: value
        case .usGallons: value / litersPerUSGallon
        case .imperialGallons: value / litersPerImperialGallon
        }
    }

    static func pricePerLiter(from price: Double, unit: VolumeUnits) -> Double {
        price / liters(from: 1, unit: unit)
    }

    static func pricePerDisplayedUnit(fromPricePerLiter price: Double, unit: VolumeUnits) -> Double {
        price * liters(from: 1, unit: unit)
    }

    static func fuelEconomy(distanceKilometers: Double, volumeLiters: Double, unit: FuelEconomyUnits) -> Double {
        guard distanceKilometers > 0, volumeLiters > 0 else { return 0 }

        return switch unit {
        case .L100km: volumeLiters / distanceKilometers * 100
        case .kmL: distanceKilometers / volumeLiters
        case .kmGal: distanceKilometers / volumeLiters * litersPerUSGallon
        case .mpg: distanceKilometers / kilometersPerMile / (volumeLiters / litersPerUSGallon)
        case .mpgImperial: distanceKilometers / kilometersPerMile / (volumeLiters / litersPerImperialGallon)
        }
    }
}

enum AppIcon: String, CaseIterable {
    case monochrome = "Monochrome", classicPurple = "Classic Purple", classicMonochrome = "Classic Monochrome"
}
