//
//  EditVehicleView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct EditVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftVehicle = DraftVehicle()
    @ObservedObject var vehicle: Vehicle
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        
        _draftVehicle = StateObject(wrappedValue: DraftVehicle(vehicle: vehicle))
    }
    
    @FetchRequest(sortDescriptors: []) var vehicles: FetchedResults<Vehicle>
    
    @FocusState var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                VStack(spacing: 20) {
                    AddEditVehicleImageView(draftVehicle: draftVehicle)
                    
                    VStack {
                        TextField("Vehicle Name", text: $draftVehicle.name)
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 5).foregroundStyle(Color(.systemGroupedBackground)))
                            .textInputAutocapitalization(.words)
                            .focused($isInputActive)
                        
                        TextField("Odometer", value: $draftVehicle.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 5).foregroundStyle(Color(.systemGroupedBackground)))
                            .keyboardType(.numberPad)
                    }
                    .multilineTextAlignment(.center)
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        vehicle.updateAndSave(draftVehicle: draftVehicle)
                        dismiss()
                    }
                    .disabled(draftVehicle.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return EditVehicleView(vehicle: vehicle)
}
