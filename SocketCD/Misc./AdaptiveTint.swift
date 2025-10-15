//
//  AdaptiveTint.swift
//  SocketCD
//
//  Created by Justin Risner on 10/15/25.
//

import SwiftUI

struct AdaptiveTint: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .tint(nil)
        } else {
            content
        }
    }
}

extension View {
    func adaptiveTint() -> some View {
        modifier(AdaptiveTint())
    }
}
