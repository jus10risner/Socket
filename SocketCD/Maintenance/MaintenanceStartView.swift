//
//  MaintenanceStartView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct MaintenanceStartView: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var showingAddService: Bool
    @State private var showingMoreInfo = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            
            VStack(spacing: 20) {
                Image(systemName: "book.and.wrench")
                    .font(.largeTitle)
                    .foregroundStyle(Color.secondary)
                    .frame(width: 50, height: 50)
                    .accessibilityHidden(true)
                
                HStack(spacing: 3) {
                    Text("Tap")
                    Button {
                        showingAddService = true
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(settings.accentColor(for: .maintenanceTheme)).symbolRenderingMode(.hierarchical)
                            .font(.title)
                    }
                    Text("to set up a new service")
                }
                .accessibilityElement()
                .accessibilityLabel("Tap the Add New Maintenance Service button, to set up a new service")
                
                Group {
                    if showingMoreInfo {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Maintenance is performed at regular intervals, to keep your vehicle in good working order.")
                            Text("Examples of maintenance services include things like oil changes and air filter replacement.")
                            Text("After you set up a new maintenance service, Socket can notify you each time it's due.")
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
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MaintenanceStartView(showingAddService: .constant(false))
        .environmentObject(AppSettings())
}
