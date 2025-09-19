//
//  RepairsListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct RepairsListView: View {
//    @EnvironmentObject var settings: AppSettings
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
        Group {
            if vehicle.sortedRepairsArray.isEmpty {
                RepairsStartView()
            } else {
                List {
                    ForEach(repairs, id: \.id) { repair in
                        NavigationLink {
                            RepairDetailView(repair: repair)
                        } label: {
                            HStack {
                                Text(repair.name)
                                
                                Spacer()
                                
                                Text(repair.date.formatted(date: .numeric, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                
                                //                                Text("\(repair.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Repairs")
        .sheet(isPresented: $showingAddRepair) {
            AddEditRepairView(vehicle: vehicle)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add New Repair", systemImage: "plus") {
                    showingAddRepair = true
                }
            }
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
