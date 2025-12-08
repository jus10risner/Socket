//
//  WhatsNewView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/23/25.
//

import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var showingTermsOfUse = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 50) {
                        Text("What's New in Socket")
                            .font(.title.bold())
                            .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            InformationItemView(title: "Now on iPad", description: "Explore your vehicle data with more room to see everything at a glance.", imageName: "ipad.and.iphone", accentColor: Color.accent)
                            
                            InformationItemView(title: "Dashboard View", description: "See important vehicle info and quickly add records, all from one place.", imageName: "rectangle.3.group", accentColor: Color.accent)
                            
                            InformationItemView(title: "Log Multiple Services", description: "Select multiple maintenance services to log at the same time.", imageName: "checkmark.circle", accentColor: Color.accent)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Button {
                    if settings.termsOfUseAccepted {
                        dismiss()
                    } else {
                        showingTermsOfUse = true
                    }
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
    WhatsNewView()
        .environmentObject(AppSettings())
}
