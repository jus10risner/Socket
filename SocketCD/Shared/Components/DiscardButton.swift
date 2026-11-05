//
//  DiscardButton.swift
//  SocketCD
//

import SwiftUI

struct DiscardButton: View {
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    init(_ accessibilityLabel: LocalizedStringKey, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(.primary.opacity(0.75))
                .padding(6)
                .background(.ultraThickMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(
            .interaction,
            Circle().inset(by: -8)
        )
        .accessibilityLabel(Text(accessibilityLabel))
    }
}
