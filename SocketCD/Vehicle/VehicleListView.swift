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
    
    @State private var showingAddVehicle = false
    @State private var showingSettings = false
    
    @Binding var showingOnboardingText: Bool // Unused, for now
    
    var body: some View {
        alternateVehicleCardList
    }
    
    
    // MARK: - Views
    
    var alternateVehicleCardList: some View {
        List(selection: $selectedVehicle) {
            ForEach(vehicles, id: \.id) { vehicle in
                Button {
                    selectedVehicle = vehicle
                } label: {
                    VehicleCardView(vehicle: vehicle)
                }
                .buttonStyle(.plain) // Allows swipeActions to work
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
                .listRowBackground(Color.clear)
            }
//            .onMove {
//                move(from: $0, to: $1)
//                try? context.save()
//            }
            
            if showingOnboardingText == true {
                onboardingTipText
            }
        }
        .overlay {
            if vehicles.isEmpty {
                EmptyVehicleListView()
            }
        }
//        .scrollContentBackground(.hidden)
//        .background(Color(.customBackground))
        .navigationTitle("Vehicles")
        .listRowSpacing(5)
//        .onAppear {
//            if vehicles.count == 1 && settings.onboardingTipsAlreadyPresented == false {
//                showingOnboardingText = true
//            }
//        }
        .sheet(isPresented: $showingSettings, onDismiss: updateNotifications) { AppSettingsView() }
        .sheet(isPresented: $showingAddVehicle) { AddVehicleView() }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Label("Add a Vehicle", systemImage: "plus")
                    }
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
                .tint(.primary)
            }
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
    
    func updateNotifications() {
        for vehicle in vehicles {
            vehicle.updateAllServiceNotifications()
        }
    }
    
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
    VehicleListView(selectedVehicle: .constant(Vehicle(context: DataController.preview.container.viewContext)), showingOnboardingText: .constant(true))
}
