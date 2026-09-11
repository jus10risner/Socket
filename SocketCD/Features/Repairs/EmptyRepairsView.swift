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
                Text("Record what you fix")
            } icon: {
                Image(systemName: "wrench.adjustable")
                    .foregroundStyle(Color(.repairsTheme))
            }
        } description: {
            Text("Use Repairs for unexpected fixes, like a flat tire or battery replacement. Add scheduled services to Maintenance.")
            .font(.body)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyRepairsView()
}
