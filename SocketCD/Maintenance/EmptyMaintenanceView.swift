//
//  EmptyMaintenanceView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct EmptyMaintenanceView: View {
    @State private var showingMoreInfo = false
    
    var body: some View {
        ContentUnavailableView {
            Label("No Maintenance Services", systemImage: "book.and.wrench")
        } description: {
            Text("Tap the book button in the top-right corner to set up a service.")
                .accessibilityHidden(true)
        } actions: {
            Button("Learn More") {
                showingMoreInfo = true
            }
            .popover(isPresented: $showingMoreInfo) {
                Text("""
                Keep your vehicle running smoothly with regular maintenance, like oil changes and air filter replacements.
                
                After you set up a new maintenance service, Socket can notify you each time it's due.
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
    EmptyMaintenanceView()
}
