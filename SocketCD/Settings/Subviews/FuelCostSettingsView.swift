//
//  FuelCostSettingsView.swift
//  SocketCD
//
//  Created by Justin Risner on 9/29/25.
//

import SwiftUI

struct FuelCostSettingsView: View {
    @EnvironmentObject var settings: AppSettingsStore
    
    var body: some View {
        List {
            Section(footer: Text("Choose how you prefer to enter fuel costs when logging fill-ups.")) {
                Picker("Fill-up Cost Type", selection: $settings.fillupCostType) {
                    ForEach(FillupCostTypes.allCases, id: \.self) { type in
                        Text(type.title)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(footer: Text(settings.fillupCostType.verificationDescription)) {
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
        .environmentObject(AppSettingsStore())
}
