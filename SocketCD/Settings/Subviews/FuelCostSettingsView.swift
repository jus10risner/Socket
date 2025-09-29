//
//  FuelCostSettingsView.swift
//  SocketCD
//
//  Created by Justin Risner on 9/29/25.
//

import SwiftUI

struct FuelCostSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            Section(footer: Text("Choose how you prefer to enter fuel costs when logging fill-ups.")) {
                Picker("Fill-up Cost Type", selection: $settings.fillupCostType) {
                    ForEach(FillupCostTypes.allCases, id: \.self) { type in
                        if type == .perUnit {
                            if settings.fuelEconomyUnit == .mpg {
                                Text("Price per gallon")
                            } else {
                                Text("Price per liter")
                            }
                        } else {
                            Text("Total cost")
                        }
                    }
                }
                .labelsHidden()
            }
            
            Section(footer: Text("Shows the \(settings.fillupCostType == .total ? "per-\(settings.fuelEconomyUnit.volumeUnit.lowercased())" : "total") cost, calculated from your input, when logging a fill-up.")) {
                Toggle("Verify Cost", isOn: $settings.showCalculatedCost)
            }
        }
        .navigationTitle("Fuel Cost")
        .navigationBarTitleDisplayMode(.inline)
        .pickerStyle(.inline)
    }
}

#Preview {
    FuelCostSettingsView()
        .environmentObject(AppSettings())
}
