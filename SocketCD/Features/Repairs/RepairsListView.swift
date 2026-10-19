//
//  RepairsListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData
import SwiftUI

struct RepairsListView: View {
    @ObservedObject var vehicle: Vehicle
    @FetchRequest var repairs: FetchedResults<Repair>

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._repairs = FetchRequest(
            entity: Repair.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Repair.date_, ascending: false)
            ],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }

    @State private var showingAddRepair = false

    var body: some View {
        List {
            ForEach(repairsByYear, id: \.year) { section in
                HistoryListSection(
                    year: section.year,
                    headerColor: AppSection.repairs.color
                ) {
                    ForEach(section.repairs, id: \.id) { repair in
                        NavigationLink {
                            RepairDetailView(repair: repair)
                        } label: {
                            HistoryListRow(
                                date: repair.date,
                                odometer: repair.odometer,
                                distanceUnit: vehicle.distanceUnit
                            ) {
                                Text(repair.name)
                            }
                        }
                    }
                }
            }
        }
        .sectionNavigationTitle(AppSection.repairs.title, vehicleName: vehicle.name)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .overlay {
            if repairs.isEmpty {
                ContentUnavailableView {
                    Label("No Repairs", systemImage: AppSection.repairs.symbol())
                } description: {
                    Text("Record unexpected work, such as battery replacement or engine repair.")
                }
            }
        }
        .sheet(isPresented: $showingAddRepair) {
            AddEditRepairView(vehicle: vehicle)
        }
        .toolbar {
            AdaptiveToolbarButton {
                Button("Add Repair", systemImage: "plus") {
                    showingAddRepair = true
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(AppSection.repairs.color)
            }
        }
    }

    var repairsByYear: [(year: Int, repairs: [Repair])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: repairs) { repair in
            calendar.component(.year, from: repair.date)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (year: $0.key, repairs: $0.value) }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345

    return RepairsListView(vehicle: vehicle)
}
