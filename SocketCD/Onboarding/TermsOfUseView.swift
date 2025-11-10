//
//  TermsOfUseView.swift
//  SocketCD
//
//  Created by Justin Risner on 11/7/25.
//

import SwiftUI

struct TermsOfUseView: View {
    @State private var termsAndConditionsAccepted = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Use")
                        .font(.title.bold())
                    
                    Text("We don’t love reading legal stuff either, so we’ve made this section as short and clear as possible:")
                        .font(.headline)
                    
                    Text("""
                        We do our best to ensure that all information is accurate and helpful, but please verify the accuracy of any information displayed in Socket. 
                        
                        This app is provided “as is,” and we cannot be held responsible for any problems, errors, or losses that may result from its use. Please remember to back up your device regularly to keep your information safe.
                        
                        By using this app, you agree to use the information responsibly and to verify it before making any decisions regarding your vehicle.
                        """)
                    
                    Spacer(minLength: 50)
                    
                    VStack(spacing: 10) {
                        Text("Thank you for using Socket!")
                            .font(.title3.bold())
                        
                        Text("We hope it helps you stay organized and confident about caring for your vehicles.")
                    }
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle.adaptive)
                }
                .padding(.horizontal)
                .interactiveDismissDisabled()
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        termsAndConditionsAccepted = true
                    } label: {
                        Text("Accept")
                            .font(.headline)
                            .padding(.vertical)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview {
    TermsOfUseView()
}
