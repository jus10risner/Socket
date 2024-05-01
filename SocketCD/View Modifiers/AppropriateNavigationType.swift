//
//  AppropriateNavigationType.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct AppropriateNavigationType<Content: View>: View {
    var content: () -> Content

    var body: some View {
        if #available(iOS 16, *) {
            SwiftUI.NavigationStack {
                content()
            }
        } else {
            NavigationView {
                content()
            }
            .navigationViewStyle(.stack)
        }
    }
}
