//
//  AdaptiveToolbarButton.swift
//  SocketCD
//
//  Created by Justin Risner on 11/7/25.
//

import Foundation
import SwiftUI

struct AdaptiveToolbarButton<Content: View>: ToolbarContent {
    let content: () -> Content
    
    var body: some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                
                content()
            }
        } else {
            ToolbarItem {
                content()
            }
        }
    }
}
