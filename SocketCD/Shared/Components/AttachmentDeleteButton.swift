//
//  AttachmentDeleteButton.swift
//  SocketCD
//

import SwiftUI

struct AttachmentDeleteButton: View {
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    init(_ accessibilityLabel: LocalizedStringKey, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "xmark")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.black.opacity(0.7), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .contentShape(
            .interaction,
            Circle().inset(by: -8)
        )
        .accessibilityLabel(Text(accessibilityLabel))
    }
}
