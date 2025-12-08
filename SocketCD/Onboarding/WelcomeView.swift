//
//  WelcomeView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    
    @State private var showingTermsOfUse = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 50) {
                        VStack(spacing: 15) {
                            Image("Primary Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80)
                                .frame(maxWidth: .infinity)
                                .environment(\.colorScheme, {
                                    if #available(iOS 18, *) {
                                        return colorScheme
                                    } else {
                                        // iOS 17: force light mode only, since icons don't adapt for light/dark
                                        return .light
                                    }
                                }())
                            
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
                }
                
                Button {
                    showingTermsOfUse = true
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: 350)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            }
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Prevents content jumping after TermsOfUseView is presented
                    Text(" ")
                        .opacity(0)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingTermsOfUse) {
                TermsOfUseView {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSettings())
}
