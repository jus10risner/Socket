//
//  ToolbarSubtitle.swift
//  SocketCD
//
//  Created by Justin Risner on 10/15/25.
//

import SwiftUI

struct ToolbarSubtitle: ViewModifier {
    let text: String
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .navigationSubtitle(text)
        } else {
            content
        }
    }
}

extension View {
    func toolbarSubtitle(_ text: String) -> some View {
        modifier(ToolbarSubtitle(text: text))
    }
}
