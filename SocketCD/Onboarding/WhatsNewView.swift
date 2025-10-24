//
//  WhatsNewView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/23/25.
//

import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    
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
                InformationItemView(title: "Dashboard View", description: "See important info and quickly add records, all from one place.", imageName: "rectangle.3.group", accentColor: settings.accentColor(for: .appTheme))
                
                InformationItemView(title: "Log Multiple Services", description: "Select multiple services to log at once, with shared notes, photos, and more.", imageName: "circle.grid.2x2.topleft.checkmark.filled", accentColor: settings.accentColor(for: .appTheme))
                
                InformationItemView(title: "New Maintenance Indicator", description: "Visualize the time or distance left until service, with a new gauge view.", imageName: "book.and.wrench", accentColor: settings.accentColor(for: .appTheme))
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
            .tint(settings.accentColor(for: .appTheme))
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    WhatsNewView()
        .environmentObject(AppSettings())
}
