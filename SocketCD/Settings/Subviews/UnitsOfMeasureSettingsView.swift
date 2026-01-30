//
//  UnitsOfMeasureSettingsView.swift
//  SocketCD
//
//  Created by Justin Risner on 9/29/25.
//

import SwiftUI

struct UnitsOfMeasureSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            Picker("Distance", selection: $settings.distanceUnit) {
                ForEach(DistanceUnits.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            
            Picker("Fuel Economy", selection: $settings.fuelEconomyUnit) {
                ForEach(FuelEconomyUnits.allCases, id: \.self) {
                    Text($0.rawValue)
                        .tag($0)
                        .accessibilityLabel($0.fullName)
                }
            }
        }
        .navigationTitle("Units of Measure")
        .navigationBarTitleDisplayMode(.inline)
        .pickerStyle(.inline)
    }
}

#Preview {
    UnitsOfMeasureSettingsView()
        .environmentObject(AppSettings())
}
