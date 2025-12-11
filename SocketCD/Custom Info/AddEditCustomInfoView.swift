//
//  AddEditCustomInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct AddEditCustomInfoView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @StateObject var draftCustomInfo = DraftCustomInfo()
    @FocusState var isInputActive: Bool
    @State private var showingDuplicateLabelError = false
    @State private var showingDeleteAlert = false
    
    // MARK: - Input
    private let vehicle: Vehicle?
    private let customInfo: CustomInfo?
    private let onDelete: (() -> Void)?
    
    // MARK: - Init
    init(vehicle: Vehicle? = nil, customInfo: CustomInfo? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.customInfo = customInfo
        self.onDelete = onDelete
        
        _draftCustomInfo = StateObject(wrappedValue: DraftCustomInfo(customInfo: customInfo))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledInput(label: "Label") {
                        TextField("License Plate", text: $draftCustomInfo.label)
                            .focused($isInputActive)
                    }
                    
                    LabeledInput(label: "Detail") {
                        TextField("ABC 123", text: $draftCustomInfo.detail)
                    }
                }
                
                FormFooterView (
                    note: $draftCustomInfo.note,
                    photos: $draftCustomInfo.photos,
                    deleteButtonTitle: "Delete Info",
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(customInfo != nil ? "Edit Info" : "New Info")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if customInfo == nil {
                    // Show keyboard after a short delay, when adding new custom info
                    DispatchQueue.main.async {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(customInfo != nil ? "Done" : "Add", systemImage: "checkmark") {
                        if let customInfo {
                            customInfo.updateAndSave(draftCustomInfo: draftCustomInfo)
                        } else if let vehicle {
                            if vehicle.sortedCustomInfoArray.contains(where: { $0.label == draftCustomInfo.label }) {
                                showingDuplicateLabelError = true
                            } else {
                                vehicle.addNewInfo(draftCustomInfo: draftCustomInfo)
                            }
                        }
                        
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftCustomInfo.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }
            }
            .alert("Delete Vehicle Info", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let customInfo {
                        DataController.shared.delete(customInfo)
                    }
                    
                    dismiss()
                    onDelete?()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Permanently delete this info? This cannot be undone.")
            }
            .alert("That label has already been used.", isPresented: $showingDuplicateLabelError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please choose a different label.")
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    let customInfo = CustomInfo(context: context)
    customInfo.label = "License Plate"
    customInfo.detail = "ABC 123"
    
    return AddEditCustomInfoView(vehicle: vehicle, customInfo: customInfo)
}
