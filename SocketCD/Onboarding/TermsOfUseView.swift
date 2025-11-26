//
//  TermsOfUseView.swift
//  SocketCD
//
//  Created by Justin Risner on 11/7/25.
//

import SwiftUI

struct TermsOfUseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    
    @State private var showingAlert: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("We don’t like reading this stuff either, so we’ve made it as short and clear as possible.")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        
                        Text("""
                        We do our best to ensure that all information is accurate and helpful, but please verify the accuracy of any information displayed in Socket. 
                        
                        This app is provided “as is,” and we cannot be held responsible for any problems, errors, or losses that may result from its use. Please remember to back up your device regularly to keep your information safe.
                        
                        By using this app, you agree to use the information responsibly and to verify it before making any decisions regarding your vehicle.
                        """)
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 20)
                }
                
                VStack {
                    Button {
                        settings.termsOfUseAccepted = true
                        dismiss()
                    } label: {
                        Text("Agree")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .frame(maxWidth: 350)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                       showingAlert = true
                    } label: {
                        Text("Disagree")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .frame(maxWidth: 350)
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 5)
            }
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
            .interactiveDismissDisabled()
            .navigationTitle("Terms of Use")
            .alert("Take your time", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You’ll need to agree to the Terms of Use before using Socket, so please come back when you're ready.")
            }
        }
    }
}

#Preview {
    TermsOfUseView()
        .environmentObject(AppSettings())
}
