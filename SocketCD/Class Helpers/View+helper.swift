//
//  View+helper.swift
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
