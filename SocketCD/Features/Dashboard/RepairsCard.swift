//
//  RepairsCard.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/25.
//

import CoreData
import SwiftUI

struct RepairsCard: View {
    @ObservedObject var vehicle: Vehicle
    let settings = AppSettingsStore.shared
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var selectedSection: AppSection?

    @FetchRequest private var repairs: FetchedResults<Repair>

    init(vehicle: Vehicle, activeSheet: Binding<ActiveSheet?>, selectedSection: Binding<AppSection?>) {
        self.vehicle = vehicle
        self._activeSheet = activeSheet
        self._selectedSection = selectedSection
        self._repairs = FetchRequest(
            entity: Repair.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Repair.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    var body: some View {
        DashboardCard(
            title: "Repairs",
            color: Color(.repairsTheme),
            quickActionTitle: "Add Repair",
            accessibilityValue: accessibilityValue,
            accessibilityHint: String(localized: "Opens repair history")
        ) {
            selectedSection = .repairs
        } quickAction: {
            activeSheet = .addRepair
        } visual: {
            CardSymbolView(symbolName: "wrench.adjustable.fill")
        } detail: {
            if let repair = repairs.first {
                CardTextView(
                    headline: latestRepairHeadline,
                    subheadline: latestRepairDescription(repair)
                )
            } else {
                CardTextView(
                    headline: "Keep a repair history",
                    subheadline: "Record unexpected vehicle work"
                )
            }
        }
    }
    
    private var latestRepairHeadline: String {
        guard repairsOnLatestDate.count > 1 else {
            return repairs.first?.name ?? String(localized: "Unknown Repair")
        }

        return String(localized: "\(repairsOnLatestDate.count) Repairs Performed")
    }

    private var repairsOnLatestDate: [Repair] {
        guard let latestRepair = repairs.first else { return [] }

        return repairs.filter {
            Calendar.current.isDate($0.date, inSameDayAs: latestRepair.date)
        }
    }
    
    private func latestRepairDescription(_ repair: Repair) -> String {
        let date: String
        if Calendar.current.isDate(repair.date, equalTo: .now, toGranularity: .year) {
            date = repair.date.formatted(.dateTime.month(.abbreviated).day())
        } else {
            date = repair.date.formatted(.dateTime.month(.abbreviated).day().year())
        }

        let odometerValues = Set(repairsOnLatestDate.map(\.odometer))
        guard odometerValues.count == 1 else { return date }

        return String(localized: "\(date) • \(repair.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
    }
    
    private var accessibilityValue: String {
        if let repair = repairs.first {
            let description = latestRepairDescription(repair)
                .replacingOccurrences(of: " • ", with: ", ")
            
            if repairsOnLatestDate.count > 1 {
                return String(localized: "\(latestRepairHeadline). \(description)")
            } else {
                return String(localized: "Latest repair: \(repair.name). \(description)")
            }
        } else {
            return String(localized: "No repairs logged")
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
