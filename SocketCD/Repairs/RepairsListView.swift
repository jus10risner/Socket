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
            if repairs.isEmpty {
                EmptyRepairsView()
            } else {
                List {
                    ForEach(repairsByYear, id: \.year) { section in
                        Section {
                            ForEach(section.repairs, id: \.id) { repair in
                                NavigationLink {
                                    RepairDetailView(repair: repair)
                                } label: {
                                    listRowItem(repair: repair)
                                }
                            }
                        } header: {
                            Text("\(section.year.formatted(.number.grouping(.never)))")
                                .foregroundStyle(Color.repairsTheme)
                        }
                        .headerProminence(.increased)
                    }
                }
            }
        }
        .navigationTitle("Repairs")
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
                .tint(Color.repairsTheme)
            }
            
            if #available(iOS 26, *) {
                ToolbarItem(placement: .principal) {
                    Text(vehicle.name)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // Repairs list row label
    private func listRowItem(repair: Repair) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(repair.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.callout.bold())
                
                Text("\(repair.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
            .frame(minWidth: 65, alignment: .leading)
            
            Divider()
            
            Text(repair.name)
        }
        .padding(.vertical, 5)
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
        .environmentObject(AppSettings())
}

