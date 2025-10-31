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
        VStack(spacing: 30) {
            Spacer()
            
            Text("""
                What's New in 
                Socket
                """)
            .multilineTextAlignment(.center)
            .font(.title.bold())
            
            VStack(alignment: .leading) {
                InformationItemView(title: "Dashboard View", description: "See important info and quickly add records, all from one place.", imageName: "rectangle.3.group", accentColor: Color.accent)
                
                InformationItemView(title: "Log Multiple Services", description: "Select multiple services to log at once, with shared notes, photos, and more.", imageName: "circle.grid.2x2.topleft.checkmark.filled", accentColor: Color.accent)
                
                InformationItemView(title: "New Maintenance Indicator", description: "Visualize the time or distance left until service, with a new gauge view.", imageName: "book.and.wrench", accentColor: Color.accent)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.title3.bold())
                    .padding(.vertical, 10)
                    .frame(maxWidth: 350)
            }
            .tint(Color.accent)
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    WhatsNewView()
}
