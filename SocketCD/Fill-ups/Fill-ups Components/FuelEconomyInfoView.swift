//
//  FuelEconomyInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct FuelEconomyInfoView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Fuel economy is only calculated between **Full Tank** fill-ups. It looks like your most recent fill-up was marked as **Partial Fill** or **Missed Fill-up**.")
                            
                            Text("See below, to learn about fuel economy calculation for different fill types.")
                        }
                        .padding()
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Partial Fill")
                                .font(.headline)
                                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                            
                            Text("This fill type helps estimate your average fuel economy.")
                            
                            Text("Detailed fuel economy tracking will resume after your next Full Tank fill-up.")
                        }
                        .padding()
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Missed Fill-up (Full Tank)")
                                .font(.headline)
                                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                            
                            Text("This fill type resets fuel economy tracking and is treated as a new starting point.")
                            
                            Text("Fuel economy will be calculated again after your next Full Tank fill-up.")
                            
                            Text("**Note:** This fill type should only be selected when your fuel tank is full. If the fuel tank was not full when this fill-up was added, your fuel economy may be inaccurate when it is calculated again.")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        .padding()
                    }
                }  header: {
                    Text("Why no fuel economy?")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .headerProminence(.increased)
            }
            .font(.subheadline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Dismiss", systemImage: "xmark") {
                        dismiss()
                    }
                    .symbolRenderingMode(.hierarchical)
                }
            }
        }
    }
}

#Preview {
    FuelEconomyInfoView()
        .environmentObject(AppSettings())
}
