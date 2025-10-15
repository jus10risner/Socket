//
//  AddEditVehicleView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct AddEditVehicleView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @StateObject var draftVehicle = DraftVehicle()
    private let vehicle: Vehicle?
    
    init(vehicle: Vehicle? = nil) {
        self.vehicle = vehicle
        _draftVehicle = StateObject(wrappedValue: DraftVehicle(vehicle: vehicle))
    }
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @FocusState var isInputActive: Bool
    
    @State private var showingDuplicateNameError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AddEditVehicleImageView(draftVehicle: draftVehicle)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                Section {
                    LabeledInput(label: "Vehicle Name") {
                        TextField("Required", text: $draftVehicle.name)
                            .textInputAutocapitalization(.words)
                            .focused($isInputActive)
                    }
                    
                    LabeledInput(label: "Odometer") {
                        TextField("Required", value: $draftVehicle.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle(vehicle != nil ? "Edit Vehicle" : "New Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if vehicle == nil {
                    // Show keyboard after a short delay, when adding a new vehicle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(vehicle != nil ? "Done" : "Add", systemImage: "checkmark") {
                        if vehicles.contains(where: { $0.name == draftVehicle.name && $0.id != vehicle?.id }) {
                            showingDuplicateNameError = true
                        } else {
                            if let vehicle {
                                vehicle.updateAndSave(draftVehicle: draftVehicle)
                            } else {
                                addNewVehicle()
                            }
                            
                            dismiss()
                        }
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftVehicle.canBeSaved ? false : true)
                }
            }
            .alert("You already have a vehicle with that name", isPresented: $showingDuplicateNameError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please choose a different name.")
            }
        }
    }
    
    
    // MARK: - Computed Properties
    
    // Assigns a display order for the vehicle being created, so it appears below any existing vehicles in the vehicle list
    private var newVehicleDisplayOrder: Int64 {
        var displayOrderArray: [Int64] = [].sorted()
        
        for vehicle in vehicles {
            displayOrderArray.append(vehicle.displayOrder)
        }
        
        if displayOrderArray.count > 0 {
            return displayOrderArray.last! + 1
        } else {
            return 0
        }
    }
    
    
    // MARK: - Methods
    
    // Creates a new vehicle object, using the information from this view
    func addNewVehicle() {
        let colorComponents = UIColor(draftVehicle.selectedColor).cgColor.components
        
        let newVehicle = Vehicle(context: context)
        newVehicle.id = UUID()
        newVehicle.name = draftVehicle.name
        newVehicle.odometer = draftVehicle.odometer ?? 0
        newVehicle.colorComponents = colorComponents
        newVehicle.photo = draftVehicle.photo
        newVehicle.displayOrder = newVehicleDisplayOrder
        
        try? context.save()
        dismiss()
    }
}

#Preview {
    AddEditVehicleView()
        .environmentObject(AppSettings())
}
