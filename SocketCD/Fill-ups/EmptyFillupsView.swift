//
//  EmptyFillupsView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct EmptyFillupsView: View {
    @State private var showingMoreInfo = false
    
    var body: some View {
        ContentUnavailableView {
            Label {
                Text("No Fill-ups")
            } icon: {
                Image(systemName: "fuelpump")
                    .foregroundStyle(Color(.fillupsTheme))
            }
        } description: {
            Text("Tap the plus button to add a fill-up.")
        } actions: {
            Button("Learn More") {
                showingMoreInfo = true
            }
            .tint(Color(.fillupsTheme))
            .popover(isPresented: $showingMoreInfo) {
                Text("""
                Socket tracks your fuel economy over time to help you drive efficiently and spot trends that might signal a problem. 
                
                Adding fill-ups regularly also keeps your odometer current, so Socket can alert you when maintenance is due.
                """)
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .padding(20)
                .padding(.vertical, 40)
                .presentationCompactAdaptation(.popover)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyFillupsView()
}
