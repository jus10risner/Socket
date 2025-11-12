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
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 50) {
                    Text("What's New in Socket")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        InformationItemView(title: "Now on iPad", description: "Explore your vehicle data with more room to see everything at a glance.", imageName: "ipad.landscape.and.iphone", accentColor: Color.accent)
                        
                        InformationItemView(title: "Dashboard View", description: "See important vehicle info and quickly add records, all from one place.", imageName: "rectangle.3.group", accentColor: Color.accent)
                        
                        InformationItemView(title: "Log Multiple Services", description: "Select multiple maintenance services to log at once, with shared notes and more.", imageName: "circle.grid.2x2.topleft.checkmark.filled", accentColor: Color.accent)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(minHeight: geo.size.height)
                .padding(.horizontal, 40)
                .interactiveDismissDisabled()
            }
        }
    }
}

#Preview {
    WhatsNewView()
}
