//
//  FillupsStartView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct FillupsStartView: View {
    @State private var showingMoreInfo = false
    
    var body: some View {
        ContentUnavailableView {
            Label("No Fill-ups", systemImage: "fuelpump")
        } description: {
            Text("Tap the plus button to add one")
        } actions: {
            Button("Learn More") {
                showingMoreInfo = true
            }
            .popover(isPresented: $showingMoreInfo) {
                Text("""
                Socket tracks your fuel economy over time to help you drive efficiently and spot trends that might signal a problem. 
                
                Adding fill-ups regularly also keeps your odometer current, so Socket can alert you when maintenance is due.
                """)
                .font(.subheadline)
                .padding(20)
                .frame(width: 350)
                .presentationCompactAdaptation(.popover)
            }
        }
    }
}

#Preview {
    FillupsStartView()
}
