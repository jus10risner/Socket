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
                Text("Record your fill-ups")
            } icon: {
                Image(systemName: "fuelpump")
                    .foregroundStyle(Color(.fillupsTheme))
            }
        } description: {
            Text("Track your fuel economy over time to understand your vehicle's efficiency and spot changes that may need attention.")
                .font(.body)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyFillupsView()
}
