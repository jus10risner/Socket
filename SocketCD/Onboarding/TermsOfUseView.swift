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
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Terms of Use")
                            .font(.title.bold())
                        
                        Text("We don’t love reading legal stuff either, so we’ve made this as short and clear as possible:")
                            .font(.headline)
                        
                        Text("""
                            We do our best to ensure that all information is accurate and helpful, but please verify the accuracy of any information displayed in Socket. 
                            
                            This app is provided “as is,” and we cannot be held responsible for any problems, errors, or losses that may result from its use. Please remember to back up your device regularly to keep your information safe.
                            
                            By using this app, you agree to use the information responsibly and to verify it before making any decisions regarding your vehicle.
                            """)
                        
                        Spacer(minLength: 0)
                        
                        VStack {
                            Text("Thank you for using Socket!")
                                .font(.headline)
                            
                            Text("We hope it helps you stay organized and confident about caring for your vehicles.")
                                .font(.callout)
                        }
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        
                        Button {
                            termsAndConditionsAccepted = true
                        } label: {
                            Text("Accept")
                                .font(.headline)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(minHeight: geo.size.height)
                    .padding(.horizontal, 20)
                    .interactiveDismissDisabled()
                }
            }
        }
    }
}

#Preview {
    TermsOfUseView()
}
