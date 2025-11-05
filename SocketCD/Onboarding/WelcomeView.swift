//
//  WelcomeView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 30) {
           Spacer()
            
            VStack(spacing: 10) {
                Image("Primary Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .environment(\.colorScheme,
                        {
                            if #available(iOS 18, *) {
                                return colorScheme
                            } else {
                                // iOS 17: force light mode only
                                return .light
                            }
                        }()
                    )
                
                Text("""
                    Welcome to
                    Socket
                    """)
                .multilineTextAlignment(.center)
            }
            .font(.largeTitle.bold())

            VStack(alignment: .leading) {
                InformationItemView(title: "Track Maintenance", description: "Get notified when it’s time for service.", imageName: "book.and.wrench", accentColor: Color(.maintenanceTheme))
                
                InformationItemView(title: "Document Repairs", description: "Keep a history of work performed and share it easily.", imageName: "wrench.adjustable", accentColor: Color(.repairsTheme))
                
                InformationItemView(title: "Log Fill-ups", description: "Track fuel economy and visualize trends over time.", imageName: "fuelpump", accentColor: Color(.fillupsTheme))
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                settings.welcomeViewPresented = false
            } label: {
                Text("Get Started")
                    .font(.title3.bold())
                    .padding(.vertical, 10)
                    .frame(maxWidth: 350)
            }
            .tint(settings.selectedAccent())
            .buttonStyle(.borderedProminent)
        }
        .interactiveDismissDisabled()
//        .padding(.horizontal, 40)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSettings())
}
