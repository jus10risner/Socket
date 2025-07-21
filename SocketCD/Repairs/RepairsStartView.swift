//
//  RepairsStartView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct RepairsStartView: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var showingAddRepair: Bool
    @State private var showingMoreInfo = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            
            VStack(spacing: 20) {
                Image(systemName: "wrench")
                    .font(.largeTitle)
                    .foregroundStyle(Color.secondary)
                    .frame(width: 50, height: 50)
                    .accessibilityHidden(true)
                
                HStack(spacing: 3) {
                    Text("Tap")
                    Button {
                        showingAddRepair = true
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(settings.accentColor(for: .repairsTheme)).symbolRenderingMode(.hierarchical)
                            .font(.title)
                    }
                    Text("to add a repair record")
                }
                .accessibilityElement()
                .accessibilityLabel("Tap the Add New Repair button, to add a repair record.")
                
                if showingMoreInfo {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Repairs are performed as-needed and are not part of scheduled vehicle maintenance.")
                        Text("Examples of repairs include things like brake pad replacement and wheel alignment.")
                        Text("Not sure if something is a repair or a maintenance service? If you need to be reminded to do it again, it should be added to Maintenance.")
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
    RepairsStartView(showingAddRepair: .constant(false))
        .environmentObject(AppSettings())
}
