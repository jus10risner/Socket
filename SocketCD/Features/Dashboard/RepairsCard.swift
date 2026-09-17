//
//  RepairsCard.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/25.
//

import SwiftUI

struct RepairsCard: View {
    @ObservedObject var vehicle: Vehicle
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var selectedSection: AppSection?
    
    var body: some View {
        DashboardCard(
            title: "Repairs",
            color: Color(.repairsTheme),
            quickActionTitle: "Add Repair",
            accessibilityValue: accessibilityValue,
            accessibilityHint: String(localized: "Opens the repair history")
        ) {
            selectedSection = .repairs
        } quickAction: {
            activeSheet = .addRepair
        } visual: {
            CardSymbolImage(symbolName: "wrench.adjustable.fill", color: Color(.repairsTheme))
        } detail: {
            if let repair = vehicle.sortedRepairsArray.first {
                CardTextView(
                    headline: latestRepairName,
                    subheadline: repair.date.formatted(date: .numeric, time: .omitted)
                )
            } else {
                CardTextView(
                    headline: "No Repairs Logged",
                    subheadline: "Your vehicle is on its best behavior"
                )
            }
        }
    }
    
    private var latestRepairName: String {
        if let latestRepair = vehicle.sortedRepairsArray.first?.name {
            return latestRepair
        } else {
            return "Unknown Repair"
        }
    }
    
    private var accessibilityValue: String {
        if let repair = vehicle.sortedRepairsArray.first {
            return String(localized: "Latest: \(repair.date.formatted(date: .numeric, time: .omitted))")
        } else {
            return "No repairs logged"
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return RepairsCard(vehicle: vehicle, activeSheet: .constant(nil), selectedSection: .constant(nil))
}
