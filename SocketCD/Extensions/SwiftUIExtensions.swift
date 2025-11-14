//
//  SwiftUIExtensions.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

extension Color {
    // Determines whether a color is a light shade, using luminosity
    var isLightColor: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: nil)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 0.7
    }
    
    // Allows mixing of system colors on iOS 17 (18 has a built-in method for doing this); used to create the appTheme color
    func mix(with color: Color, by percentage: Double) -> Color {
        let clampedPercentage = min(max(percentage, 0), 1)
        
        let components1 = UIColor(self).cgColor.components!
        let components2 = UIColor(color).cgColor.components!
        
        let red = (1.0 - clampedPercentage) * components1[0] + clampedPercentage * components2[0]
        let green = (1.0 - clampedPercentage) * components1[1] + clampedPercentage * components2[1]
        let blue = (1.0 - clampedPercentage) * components1[2] + clampedPercentage * components2[2]
        let alpha = (1.0 - clampedPercentage) * components1[3] + clampedPercentage * components2[3]
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension RoundedRectangle {
    
    // Sets the appropriate corner radius, based on iOS version
    static var adaptive: RoundedRectangle {
        if #available(iOS 26, *) {
            return RoundedRectangle(cornerRadius: 26)
        } else {
            return RoundedRectangle(cornerRadius: 12)
        }
    }
}
