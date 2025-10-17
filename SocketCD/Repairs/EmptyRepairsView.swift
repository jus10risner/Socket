//
//  EmptyRepairsView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct EmptyRepairsView: View {
    @State private var showingMoreInfo = false
    
    var body: some View {
        ContentUnavailableView {
            Label("No Repairs", systemImage: "wrench.adjustable")
        } description: {
            Text("Tap the plus button to add one")
        } actions: {
            Button("Learn More") {
                showingMoreInfo = true
            }
            .popover(isPresented: $showingMoreInfo) {
                Text("""
                Repairs, like replacing brake pads or a failing alternator, are done as-needed rather than on a schedule. 
                
                Want a reminder to do sometihg again? Add it to Maintenance.
                """)
                .font(.subheadline)
                .padding(20)
                .frame(width: 350)
                .presentationCompactAdaptation(.popover)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyRepairsView()
}
