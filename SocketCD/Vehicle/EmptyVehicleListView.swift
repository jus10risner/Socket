//
//  EmptyVehicleListView.swift
//  SocketCD
//
//  Created by Justin Risner on 5/16/24.
//

import SwiftUI

struct EmptyVehicleListView: View {
    var body: some View {
        ZStack {
            Color(.customBackground)
            
            VStack(spacing: 10) {
                Image(systemName: "car.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color(.socketPurple))
                    .accessibilityHidden(true)
                
                VStack {
                    Text("Add a Vehicle")
                        .font(.title2.bold())
                    
                    Text("Tap the plus button to get started.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityElement()
                .accessibilityLabel("Tap the Add a Vehicle button to get started")
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    EmptyVehicleListView()
}
