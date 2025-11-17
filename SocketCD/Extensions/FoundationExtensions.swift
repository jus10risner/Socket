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

extension Optional where Wrapped: Numeric & Comparable {
    
    // Used to check whether fields inside forms have a value (where the value could be either nil or 0 for "blank" state)
    var hasValue: Bool {
        guard let v = self else { return false }
        return v != 0
    }
}

extension String {
    
    // Used to determine whether a String contains any characters other than blank spaces
    var isBlank: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
