//
//  RepairsListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct RepairsListView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var vehicle: Vehicle
    
    @FetchRequest var repairs: FetchedResults<Repair>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._repairs = FetchRequest(
            entity: Repair.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Repair.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var showingAddRepair = false
    
    var body: some View {
        ZStack {
            if vehicle.sortedRepairsArray.isEmpty {
                EmptyRepairsView()
            } else {
                List {
                    ForEach(repairs, id: \.id) { repair in
                        NavigationLink {
                            RepairDetailView(repair: repair)
                        } label: {
                            listRowItem(repair: repair)
                        }
                    }
                }
                .listRowSpacing(5)
            }
        }
        .navigationTitle("Repairs")
        .toolbarSubtitle(vehicle.name)
        .sheet(isPresented: $showingAddRepair) {
            AddEditRepairView(vehicle: vehicle)
        }
        .toolbar {
            if #available(iOS 26, *) {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    
                    Button("Add New Repair", systemImage: "plus", role: .confirm) {
                        showingAddRepair = true
                    }
                    .tint(Color(.repairsTheme))
                }
            } else {
                ToolbarItem {
                    Button("Add New Repair", systemImage: "plus") {
                        showingAddRepair = true
                    }
                }
            }
        }
    }
    
    // Repairs list row label
    private func listRowItem(repair: Repair) -> some View {
        VStack(alignment: .leading) {
            Text(repair.name)
                .font(.headline)

            HStack(spacing: 5) {
                Text(repair.date.formatted(date: .numeric, time: .omitted))
                Text("•")
                Text("\(repair.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return RepairsListView(vehicle: vehicle)
        .environmentObject(AppSettings())
}
