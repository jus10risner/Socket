//
//  DashboardCard.swift
//  SocketCD
//
//  Created by Justin Risner on 8/22/25.
//

import SwiftUI

struct DashboardCard<Content: View>: View {
    let title: String
    let systemImage: String
    let accentColor: Color
    let buttonLabel: String
    let quickAction: () -> Void
    let content: Content?
    
    init(title: String, systemImage: String, accentColor: Color, buttonLabel: String, quickAction: @escaping () -> Void, @ViewBuilder content: () -> Content? = { nil }) {
        self.title = title
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.buttonLabel = buttonLabel
        self.quickAction = quickAction
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack(spacing: 3) {
                    Image(systemName: systemImage)
                        .frame(width: 20)
                    
                    Text(title)
                }
                .foregroundStyle(accentColor)
                .font(.subheadline.bold())
                .accessibilityLabel(title)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            HStack(alignment: .bottom) {
                if let content {
                    content
                }
                
                Spacer()
                
                Button(buttonLabel, systemImage: "plus", action: quickAction)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .labelStyle(.iconOnly)
                    .tint(accentColor)
            }
        }
        .frame(height: 80)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
        .contentShape(Rectangle())
    }
}

#Preview {
    DashboardCard(title: "Maintenance", systemImage: "book.and.wrench.fill", accentColor: .blue, buttonLabel: "Add", quickAction: {}, content: {})
}
