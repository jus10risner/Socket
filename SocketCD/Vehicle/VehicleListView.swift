//
//  VehicleListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct VehicleListView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Binding var selectedVehicle: Vehicle?
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @State private var showingAddVehicle = false
    @State private var showingSettings = false
    
    @Binding var showingOnboardingText: Bool // Unused, for now
    
    var body: some View {
        Group {
            if vehicles.isEmpty {
                EmptyVehicleListView()
            } else {
                List(selection: $selectedVehicle) {
                    ForEach(vehicles) { vehicle in
                        VehicleListRowView(vehicle: vehicle, isSelected: selectedVehicle == vehicle)
                            .onTapGesture {
                                selectedVehicle = vehicle
                            }
                    }
                    .onMove {
                        move(from: $0, to: $1)
                        try? context.save()
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .navigationTitle("Vehicles")
        .navigationBarTitleDisplayMode(.large)
        .listRowSpacing(5)
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingSettings) {
            AppSettingsView()
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddEditVehicleView()
        }
        .toolbar {
            ToolbarItem{
                Button("Add a Vehicle", systemImage: "plus") {
                    showingAddVehicle = true
                }
                .adaptiveTint()
            }
            
            if #available(iOS 26, *) {
                ToolbarSpacer()
            }
            
            ToolbarItem {
                Button("Settings", systemImage: "gearshape") {
                    showingSettings = true
                }
                .adaptiveTint()
            }
        }
    }
    
    // MARK: - Methods
    
    
//    var iCloudContainerAvailable: Bool {
//        FileManager.default.ubiquityIdentityToken != nil
//    }
    
    // Persists the order of vehicles, after moving
    func move(from source: IndexSet, to destination: Int) {
        // Make an array of vehicles from fetched results
        var modifiedVehicleList: [Vehicle] = vehicles.map { $0 }

        // change the order of the vehicles in the array
        modifiedVehicleList.move(fromOffsets: source, toOffset: destination )

        // update the displayOrder attribute in modifiedVehicleList to
        // persist the new order.
        for index in (0..<modifiedVehicleList.count) {
            modifiedVehicleList[index].displayOrder = Int64(index)
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleListView(selectedVehicle: .constant(vehicle), showingOnboardingText: .constant(true))
}
