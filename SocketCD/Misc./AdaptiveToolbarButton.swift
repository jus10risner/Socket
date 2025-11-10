//
//  AdaptiveToolbarButton.swift
//  SocketCD
//
//  Created by Justin Risner on 11/7/25.
//

import Foundation
import SwiftUI

struct AdaptiveToolbarButton: ToolbarContent {
    let title: String
    let tint: Color
    var disabled: Bool
    let action: () -> Void
    
    init(title: String, tint: Color, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.disabled = disabled
        self.action = action
    }
    
    var body: some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                
                Button(title, systemImage: "plus", role: .confirm) {
                    action()
                }
                .tint(tint)
                .disabled(disabled)
            }
        } else {
            ToolbarItem {
                Button(title, systemImage: "plus") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(tint)
                .disabled(disabled)
            }
        }
    }
}
