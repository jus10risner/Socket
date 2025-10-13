//
//  EmptyVehicleListView.swift
//  SocketCD
//
//  Created by Justin Risner on 5/16/24.
//

import SwiftUI

struct EmptyVehicleListView: View {
    @StateObject var monitor = CloudKitSyncMonitor(container: DataController.shared.container)
    
    var body: some View {
        ZStack {
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
            
            VStack {
                Spacer()
                
                if monitor.isSyncing == true {
                    HStack {
                        ProgressView()
                        
                        Text("Checking for iCloud data")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    EmptyVehicleListView()
}
