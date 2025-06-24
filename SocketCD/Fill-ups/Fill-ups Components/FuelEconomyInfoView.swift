//
//  FuelEconomyInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct FuelEconomyInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        fuelEconomyInfo
    }
    
    
    // MARK: - Views
    
    private var fuelEconomyInfo: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Fuel economy is only calculated between consecutive **Full Tank** fill-ups. It looks like one of your most recent fill-ups was a **Partial Fill** or **Missed Fill-up**.")
                            
                            Text("See below, to learn about fuel economy calculation for different fill types.")
                        }
                        .padding()
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Partial Fill")
                                .font(.headline)
                                .foregroundStyle(Color.selectedColor(for: .fillupsTheme))
                            
                            Text("This fill type is used only to estimate average fuel economy for this vehicle.")
                            
                            Text("Fuel economy calculation will resume after two consecutive Full Tank fill-ups have been added.")
                        }
                        .padding()
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Missed Fill-up")
                                .font(.headline)
                                .foregroundStyle(Color.selectedColor(for: .fillupsTheme))
                            
                            Text("This fill type is treated like your very first fill-up, and fuel economy is not calculated.")
                            
                            Text("Fuel economy calculation will resume after one more Full Tank fill-up has been added.")
                            
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityLabel("Dismiss")
                    }
                }
            }
        }
    }
}

#Preview {
    FuelEconomyInfoView()
}
