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
        ZStack {
            Color(.systemGroupedBackground)
            
            VStack(spacing: 20) {
                Image(systemName: "fuelpump")
                    .font(.largeTitle)
                    .foregroundStyle(Color.secondary)
                    .accessibilityHidden(true)
                
                HStack(spacing: 3) {
                    Text("Tap")
                    Image(systemName: "plus.circle.fill").foregroundStyle(Color.selectedColor(for: .fillupsTheme)).symbolRenderingMode(.hierarchical)
                        .font(.title)
                    Text("to add a fill-up")
                }
                .accessibilityElement()
                .accessibilityLabel("Tap the Add New Fill-up button, to add a fill-up.")
                
                if showingMoreInfo {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Socket tracks fuel economy over time, to encourage you to drive efficiently, and to help you spot trends that could indicate problems with your vehicle.")
                        Text("Regularly adding fill-ups also keeps Socket up-to-date on your vehicle's odometer reading, which may be used to alert you when maintenance is due.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 60)
                    .accessibilityElement(children: .combine)
                } else {
                    Button("Learn More") {
                        withAnimation {
                            showingMoreInfo = true
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    FillupsStartView()
}
