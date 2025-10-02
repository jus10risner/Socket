//
//  DashboardCard.swift
//  SocketCD
//
//  Created by Justin Risner on 8/22/25.
//

import SwiftUI

struct DashboardCard<Content: View>: View {
    let title: String
    let headerSymbol: String
    let accentColor: Color
    let buttonLabel: String
    let buttonSymbol: String
    let showingAddButton: Bool
    let quickAction: () -> Void
    let content: Content?
    
    init(title: String, systemImage: String, accentColor: Color, buttonLabel: String, buttonSymbol: String, showingAddButton: Bool = true, quickAction: @escaping () -> Void, @ViewBuilder content: () -> Content? = { nil }) {
        self.title = title
        self.headerSymbol = systemImage
        self.accentColor = accentColor
        self.buttonLabel = buttonLabel
        self.buttonSymbol = buttonSymbol
        self.showingAddButton = showingAddButton
        self.quickAction = quickAction
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack(spacing: 3) {
                    Image(systemName: headerSymbol)
                        .frame(width: 20)
                    
                    Text(title)
                }
                .foregroundStyle(accentColor)
                .font(.subheadline.bold())
                .accessibilityLabel(title)
                
                Spacer()
                
                if buttonSymbol == "plus" {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
            
            HStack(alignment: .bottom) {
                if let content {
                    content
                }
                
                Spacer()
                
                Button(buttonLabel, systemImage: buttonSymbol, action: quickAction)
                    .labelStyle(.iconOnly)
                    .tint(accentColor)
                    .padding(8)
                    .background(accentColor.opacity(0.2), in: Circle())
                    .opacity(showingAddButton ? 1 : 0)
            }
        }
        .frame(height: 80)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
        .contentShape(Rectangle())
    }
}

#Preview {
    DashboardCard(title: "Maintenance", systemImage: "book.and.wrench.fill", accentColor: .blue, buttonLabel: "Add", buttonSymbol: "plus", quickAction: {}, content: {})
}
