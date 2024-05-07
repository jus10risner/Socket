//
//  ConditionalListRowSpacing.swift
//  SocketCD
//
//  Created by Justin Risner on 3/21/24.
//

import SwiftUI

// iOS 15 doesn't round the corners of each list item when spacing is applied, which looks unpolished. This modifier adds list row spacing only to iOS 16+.
struct ConditionalListRowSpacing: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .listRowSpacing(5)
        } else {
            content
        }
    }
}
