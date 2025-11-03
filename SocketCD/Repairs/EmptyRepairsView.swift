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
            Label {
                Text("No Repairs")
            } icon: {
                Image(systemName: "wrench.adjustable")
                    .foregroundStyle(Color(.repairsTheme))
            }
        } description: {
            Text("Tap the plus button to add a repair.")
        } actions: {
            Button("Learn More") {
                showingMoreInfo = true
            }
            .tint(Color(.repairsTheme))
            .popover(isPresented: $showingMoreInfo) {
                Text("""
                Repairs, like replacing brake pads or a failing alternator, are done as-needed rather than on a schedule. 
                
                Want a reminder to do something again? Add it to Maintenance.
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
