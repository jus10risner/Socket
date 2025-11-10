//
//  WhatsNewView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/23/25.
//

import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("What's New in Socket")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 50)
                
                VStack(alignment: .leading, spacing: 15) {
                    InformationItemView(title: "Now on iPad", description: "Explore your vehicle data with more room to see everything at a glance.", imageName: "ipad.landscape.and.iphone", accentColor: Color.accent)
                    
                    InformationItemView(title: "Dashboard View", description: "See important vehicle info and quickly add records, all from one place.", imageName: "rectangle.3.group", accentColor: Color.accent)
                    
                    InformationItemView(title: "Log Multiple Services", description: "Select multiple maintenance services to log at once, with shared notes and more.", imageName: "circle.grid.2x2.topleft.checkmark.filled", accentColor: Color.accent)
                }
            }
            .padding(.horizontal, 40)
            .interactiveDismissDisabled()
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .padding(.vertical)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    WhatsNewView()
}
