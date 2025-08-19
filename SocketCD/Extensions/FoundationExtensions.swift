//
//  FoundationExtensions.swift
//  SocketCD
//
//  Created by Justin Risner on 7/21/25.
//

import Foundation

extension Double {
    
    // Takes a Double value, and converts it into a localized currency string (e.g. 1.23 -> "$1.23")
    func asCurrency(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale

        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
