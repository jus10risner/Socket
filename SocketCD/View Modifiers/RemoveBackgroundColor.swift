//
//  RemoveBackgroundColor.swift
//  SocketCD
//
//  Created by Justin Risner on 5/21/24.
//

import SwiftUI

struct RemoveBackgroundColor: ViewModifier {
//    let isInputActive: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}
