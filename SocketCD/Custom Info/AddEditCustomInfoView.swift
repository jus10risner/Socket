//
//  AddEditCustomInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct AddEditCustomInfoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftCustomInfo = DraftCustomInfo()
    let vehicle: Vehicle?
    let customInfo: CustomInfo?
    var onDelete: (() -> Void)?
    
    init(vehicle: Vehicle? = nil, customInfo: CustomInfo? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.customInfo = customInfo
        self.onDelete = onDelete
        
        _draftCustomInfo = StateObject(wrappedValue: DraftCustomInfo(customInfo: customInfo))
    }
    
    @State private var showingDuplicateLabelError = false
    @State private var showingDeleteAlert = false
    
    @FocusState var isInputActive: Bool
    
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
                } header: {
                    if let vehicle {
                        Text(vehicle.name)
                            .font(.body)
                            .frame(maxWidth: .infinity)
                    }
                }
                .headerProminence(.increased)
                
                FormFooterView (
                    note: $draftCustomInfo.note,
                    photos: $draftCustomInfo.photos,
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(customInfo != nil ? "Edit Info" : "New Info")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if customInfo == nil {
                    // Show keyboard after a short delay, when adding new custom info
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
                    .disabled(draftCustomInfo.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
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
    
    AddEditCustomInfoView(vehicle: Vehicle(context: context), customInfo: CustomInfo(context: context))
}
