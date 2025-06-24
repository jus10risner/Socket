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
    @EnvironmentObject var settings: AppSettings
    @Binding var selectedVehicle: Vehicle?
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @State private var quickFillupVehicle: Vehicle?
    @State private var quickEditVehicle: Vehicle?
    
    @State private var vehicleToDelete: Vehicle?
    @State private var showingDeleteAlert = false
    
    @Binding var showingOnboardingText: Bool
    
    var body: some View {
        vehicleCardList
    }
    
    
    // MARK: - Views
    
    var vehicleCardList: some View {
        List {
            ForEach(vehicles, id: \.id) { vehicle in
                Button {
                    selectedVehicle = vehicle
                } label: {
                    VehicleCardView(vehicle: vehicle, quickFillupVehicle: $quickFillupVehicle, quickEditVehicle: $quickEditVehicle, vehicleToDelete: $vehicleToDelete, showingDeleteAlert: $showingDeleteAlert)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
                .swipeActions(edge: .leading) {
                    Button {
                        quickFillupVehicle = vehicle
                    } label: {
                        Label("", systemImage: "fuelpump")
                            .accessibility(label: Text("Add Fill-up"))
                    }
                    .tint(Color.defaultFillupsAccent)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        vehicleToDelete = vehicle
                        showingDeleteAlert = true
                    } label: {
                        Label("", systemImage: "trash")
                            .accessibility(label: Text("Delete Vehicle"))
                    }
                    .tint(Color.red)
                    
                    Button {
                        quickEditVehicle = vehicle
                    } label: {
                        Label("", systemImage: "pencil")
                            .accessibility(label: Text("Edit Vehicle"))
                    }
                    .tint(Color.defaultAppAccent)
                }
            }
            .onMove {
                move(from: $0, to: $1)
                try? context.save()
            }
            .onDrag {
                // Allows iOS 15 to use drag gesture to rearrange vehicles
                return NSItemProvider()
            }
            .listRowBackground(Color(.customBackground))
            
            if showingOnboardingText == true {
                onboardingTipText
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: Array(vehicles))
        .onAppear {
            if vehicles.count == 1 && settings.onboardingTipsAlreadyPresented == false {
                showingOnboardingText = true
            }
        }
        .sheet(item: $quickFillupVehicle) { vehicle in
            AddFillupView(vehicle: vehicle, quickFill: true)
                .tint(Color.selectedColor(for: .fillupsTheme))
        }
        .sheet(item: $quickEditVehicle) { vehicle in
            EditVehicleView(vehicle: vehicle)
                .tint(Color.selectedColor(for: .appTheme))
        }
        .confirmationDialog("Permanently delete \(vehicleToDelete?.name ?? "this vehicle") and all of its records? \nThis cannot be undone.", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            
            Button("Delete", role: .destructive) {
                withAnimation {
                    if let vehicleToDelete {
                        delete(vehicle: vehicleToDelete)
                    }
                    
                    vehicleToDelete = nil
                }
            }
            
            Button("Cancel", role: .cancel) { vehicleToDelete = nil }
        }
    }
    
    // Tip that displays immediately after the first vehicle has been added, until another view is shown
    private var onboardingTipText: some View {
        Section {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.socketPurple)
                    .accessibilityElement()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("You can swipe on a vehicle, to quickly add fill-ups or make changes to that vehicle, right from this screen.")
                    
                    Text("When you're ready, tap your vehicle to begin adding maintenance services, repairs, and more.")
                }
                .padding(30)
                .font(.subheadline)
                .foregroundStyle(Color.white)
                .accessibilityElement(children: .combine)
            }
            .padding(.top, 30)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.customBackground)
        }
    }
    
    // MARK: - Methods
    
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
    
    // Deletes a given vehicle from Core Data
    func delete(vehicle: Vehicle) {
        context.delete(vehicle)
        try? context.save()
    }
}

#Preview {
    VehicleListView(selectedVehicle: .constant(Vehicle(context: DataController.preview.container.viewContext)), showingOnboardingText: .constant(true))
}
