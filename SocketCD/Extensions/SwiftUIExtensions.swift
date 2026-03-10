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
