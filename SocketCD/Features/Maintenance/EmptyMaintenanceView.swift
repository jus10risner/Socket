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
            Label {
                Text("Track your maintenance")
            } icon: {
                Image(systemName: "book.and.wrench")
                    .foregroundStyle(Color(.maintenanceTheme))
            }
        } description: {
            Text("Set up recurring services like oil changes or tire rotations. Once a service is set up, you can log each time you complete it and get reminders when it’s due.")
                .font(.body)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyMaintenanceView()
}
