//
//  FormHeaderView.swift
//  SocketCD
//
//  Created by Justin Risner on 11/3/25.
//

import SwiftUI

struct FormHeaderView<Content: View>: View {
    let symbolName: String
    let primaryText: String
    let secondaryText: String?
    let accentColor: Color
    let content: () -> Content
    
    init(symbolName: String, primaryText: String, secondaryText: String? = nil, accentColor: Color, @ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.symbolName = symbolName
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.accentColor = accentColor
        self.content = content
    }
    
    var body: some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: symbolName)
                    .font(.largeTitle)
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)
                
                VStack(spacing: 0) {
                    Text(primaryText)
                        .font(.title2.bold())
                    
                    if let secondaryText {
                        Text(secondaryText)
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                content()
            }
            .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}

#Preview {
    FormHeaderView(symbolName: "wrench.adjustable.fill", primaryText: "New Repair", accentColor: Color.repairsTheme, content: {})
}
