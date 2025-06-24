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
    
    @State private var inputImage: UIImage?
    @State private var image: Image?
    
    @FocusState var isInputActive: Bool
    @FocusState var fieldInFocus: Bool
    
    var body: some View {
        editVehicleForm
    }
    
    
    // MARK: - Views
    
    private var editVehicleForm: some View {
        NavigationStack {
            Form {
                VStack(spacing: 20) {
                    VStack {
                        AddEditVehicleImageView(draftVehicle: draftVehicle)
                        
                        VehiclePhotoCustomizationButtons(inputImage: $inputImage, image: $image, carPhoto: $draftVehicle.photo, selectedColor: $draftVehicle.selectedColor)
                    }
                    
                    VStack {
                        TextField("Vehicle Name", text: $draftVehicle.name)
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 5).foregroundStyle(Color(.systemGroupedBackground)))
                            .textInputAutocapitalization(.words)
                            .focused($fieldInFocus)
                        
                        TextField("Odometer", value: $draftVehicle.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 5).foregroundStyle(Color(.systemGroupedBackground)))
                            .keyboardType(.numberPad)
                    }
                    .focused($isInputActive)
                    .multilineTextAlignment(.center)
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        vehicle.updateAndSave(draftVehicle: draftVehicle)
                        dismiss()
                    }
                    .disabled(draftVehicle.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}
