//
//  SwipeToDismissKeyboard.swift
//  SocketCD
//
//  Created by Justin Risner on 3/25/24.
//

import SwiftUI

struct SwipeToDismissKeyboard: ViewModifier {
//    let isInputActive: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .scrollDismissesKeyboard(.interactively)
        } else {
            content
//                .onTapGesture() {
//                    // Dismisses keyboard when tapping anywhere outside of a text field
//                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                }
//                // Preserves Picker function, when attaching .onTapGesure to a view
//                .gesture(TapGesture(), including: isInputActive ? .all : .none)
        }
    }
}
