//
//  EmptyVehicleListView.swift
//  SocketCD
//
//  Created by Justin Risner on 5/16/24.
//

import SwiftUI

struct EmptyVehicleListView: View {
    var body: some View {
        ContentUnavailableView {
            Label {
                Text("Add a Vehicle")
            } icon: {
                Image(systemName: "car.fill")
                    .foregroundStyle(Color(.socketPurple))
            }
        } description: {
            Text("Tap the plus button to get started.")
        }
    }
}

#Preview {
    EmptyVehicleListView()
}
