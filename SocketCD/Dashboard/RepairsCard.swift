//
//  RepairsCard.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/25.
//

import SwiftUI

struct RepairsCard: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var vehicle: Vehicle
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var selectedSection: AppSection?
    
    var body: some View {
        DashboardCard(title: "Repairs", systemImage: "wrench.adjustable.fill", accentColor: settings.accentColor(for: .repairsTheme), buttonLabel: "Add Repair", buttonSymbol: "plus.circle.fill") {
            activeSheet = .addRepair
        } content: {
            if let repair = vehicle.sortedRepairsArray.first {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Latest")
                        .font(.footnote.bold())
                        .foregroundStyle(Color.secondary)
                    
                    Text(repair.date.formatted(date: .numeric, time: .omitted))
                        .font(.headline)
                }
            } else {
                Text("No entries")
                    .font(.headline)
                    .foregroundStyle(Color.secondary)
            }
        }
        .onTapGesture {
            selectedSection = .repairs
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return RepairsCard(vehicle: vehicle, activeSheet: .constant(nil), selectedSection: .constant(nil))
        .environmentObject(AppSettings())
}
