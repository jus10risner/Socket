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
        ScrollView {
            VStack(alignment: .leading, spacing: 50) {
                VStack(spacing: 15) {
                    Image("Primary Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                        .padding(.top, 50)
                        .frame(maxWidth: .infinity)
                        .environment(\.colorScheme, {
                            if #available(iOS 18, *) {
                                return colorScheme
                            } else {
                                // iOS 17: force light mode only, since icons don't adapt for light/dark
                                return .light
                            }
                        }()
                        )
                    
                    Text("Welcome to Socket")
                        .font(.title.bold())
                }
                
                
                VStack(alignment: .leading, spacing: 15) {
                    InformationItemView(title: "Track Maintenance", description: "Log services and get notified when each one is due.", imageName: "book.and.wrench.fill", accentColor: Color.maintenanceTheme)
                    
                    InformationItemView(title: "Document Repairs", description: "Maintain a clear repair history and share it whenever you want.", imageName: "wrench.adjustable.fill", accentColor: Color.repairsTheme)
                    
                    InformationItemView(title: "Log Fill-ups", description: "Track fuel economy and visualize trends over time.", imageName: "fuelpump.fill", accentColor: Color.fillupsTheme)
                }
            }
            .padding(.horizontal, 40)
            .interactiveDismissDisabled()
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    settings.welcomeViewPresented = false
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSettings())
}
