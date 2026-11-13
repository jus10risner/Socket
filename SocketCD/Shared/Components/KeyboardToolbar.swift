//
//  KeyboardToolbar.swift
//  SocketCD
//
//  Created by Justin Risner on 11/10/26.
//

import SwiftUI

struct KeyboardToolbar: View {
    let canMovePrevious: Bool
    let canMoveNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        controls
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .adaptiveKeyboardToolbarStyle()    }

    var controls: some View {
        HStack(spacing: 20) {
            Button("Previous Field", systemImage: "chevron.up", action: onPrevious)
                .disabled(!canMovePrevious)
            
            Button("Next Field", systemImage: "chevron.down", action: onNext)
                .disabled(!canMoveNext)
            
            Spacer()
            
            Button("Done", systemImage: "checkmark", action: onDone)
                .accessibilityHint("Dismisses the keyboard")
                .modify { view in
                    if #available(iOS 26.0, *) {
                        view
                    } else {
                        view.labelStyle(.titleOnly)
                    }
                }
        }
        .fontWeight(.semibold)
        .labelStyle(.iconOnly)
        .imageScale(.large)
        .dynamicTypeSize(.medium)
    }
}

private struct KeyboardToolbarStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Capsule())
                .glassEffect()
                .padding(.horizontal)
                .padding(.bottom, 8)
        } else {
            content
                .background(.bar)
                .overlay(Divider(), alignment: .top)
        }
    }
}

private extension View {
    func adaptiveKeyboardToolbarStyle() -> some View {
        self.modifier(KeyboardToolbarStyle())
    }
    
    func modify<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> some View {
        transform(self)
    }
}

#Preview {
    KeyboardToolbar(canMovePrevious: true, canMoveNext: true, onPrevious: {}, onNext: {}, onDone: {})
}
