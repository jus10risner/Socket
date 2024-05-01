//
//  Color+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

extension Color {
    
    // Returns the appropriate accent color to use for a given view component
    static func selectedColor(for availableTheme: AvailableThemes) -> Color {
        let settings = AppSettings()
        let accentColor = settings.accentColor
        
        switch availableTheme {
        case .appTheme:
            if let accentColor {
                return settings.colorValue(for: accentColor)
            } else {
                return .defaultAppAccent
            }
        case .maintenanceTheme:
            if let accentColor {
                return settings.colorValue(for: accentColor)
            } else {
                return .defaultMaintenanceAccent
            }
        case .repairsTheme:
            if let accentColor {
                return settings.colorValue(for: accentColor)
            } else {
                return .defaultRepairsAccent
            }
        case .fillupsTheme:
            if let accentColor {
                return settings.colorValue(for: accentColor)
            } else {
                return .defaultFillupsAccent
            }
        }
    }
}
