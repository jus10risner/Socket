//
//  AutoSelectAllModifier.swift
//  SocketCD
//
//  Created by Justin Risner on 11/3/26.
//

import SwiftUI

struct AutoSelectAllModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, gainedFocus in
                if gainedFocus {
                    DispatchQueue.main.async {
                        guard isFocused else { return }

                        UIApplication.shared.sendAction(
                            #selector(UIResponder.selectAll(_:)),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
    }
}

// Clean extension syntax
extension View {
    func selectAllOnFocus() -> some View {
        self.modifier(AutoSelectAllModifier())
    }
}
