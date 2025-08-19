//
//  SwiftUIExtensions.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

extension View {
    @ViewBuilder
    func colorSchemeBackground(colorScheme: ColorScheme) -> some View {
      if colorScheme == .dark {
        foregroundStyle(Color(.darkGray).opacity(0.3))
      } else {
        foregroundStyle(Color(.secondarySystemGroupedBackground))
      }
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
