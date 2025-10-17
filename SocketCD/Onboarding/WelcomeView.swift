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
    
    var body: some View {
        welcomeInfo
    }
    
    
    // MARK: - Views
    
    private var welcomeInfo: some View {
        VStack {
           Spacer()
            
            VStack(spacing: 0) {
                Image("Primary Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 10)
                
                Text("Welcome to")
                
                Text("Socket")
            }
            .font(.largeTitle.bold())
            
            Spacer()

            VStack(alignment: .leading, spacing: 30) {
                maintenanceBlurb

                repairsBlurb

                fillupsBlurb
            }
            .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            Spacer()
            
            Button {
                settings.welcomeViewPresented = false
            } label: {
                Text("Continue")
                    .font(.title3.bold())
                    .padding(.vertical, 10)
                    .frame(maxWidth: 350)
            }
            .buttonStyle(.borderedProminent)
        }
        .interactiveDismissDisabled()
        .padding(.horizontal, 40)
    }
    
    // Short intro to Maintenance in Socket
    private var maintenanceBlurb: some View {
        HStack(spacing: 15) {
            Image(systemName: "book.and.wrench.fill")
                .font(.title)
                .foregroundStyle(settings.accentColor(for: .maintenanceTheme))
                .frame(minWidth: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading) {
                Text("Maintain Vehicles")
                    .font(.subheadline.bold())
                Text("Get reminders when routine maintenance services are due.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
    
    // Short intro to Repairs in Socket
    private var repairsBlurb: some View {
        HStack(spacing: 15) {
            Image(systemName: "wrench.adjustable.fill")
                .font(.title)
                .foregroundStyle(settings.accentColor(for: .repairsTheme))
                .frame(minWidth: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading) {
                Text("Document Repairs")
                    .font(.subheadline.bold())
                Text("Save and share information about work performed on each vehicle.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
    
    // Short intro to Fill-ups in Socket
    private var fillupsBlurb: some View {
        HStack(spacing: 15) {
            Image(systemName: "fuelpump.fill")
                .font(.title)
                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                .frame(minWidth: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading) {
                Text("Log Fill-ups")
                    .font(.subheadline.bold())
                Text("Track fuel economy and visualize trends over time.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSettings())
}
