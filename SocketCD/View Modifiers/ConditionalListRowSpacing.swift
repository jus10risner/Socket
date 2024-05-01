//
//  ConditionalListRowSpacing.swift
//  SocketCD
//
//  Created by Justin Risner on 3/21/24.
//

import SwiftUI

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
