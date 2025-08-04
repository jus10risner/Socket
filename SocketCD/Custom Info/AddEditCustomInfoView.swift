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
    
    init(vehicle: Vehicle? = nil, customInfo: CustomInfo? = nil) {
        self.vehicle = vehicle
        self.customInfo = customInfo
        
        _draftCustomInfo = StateObject(wrappedValue: DraftCustomInfo(customInfo: customInfo))
    }
    
    @State private var showingDuplicateLabelError = false
    
    @FocusState var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledInput(label: "Label") {
                        TextField("License Plate", text: $draftCustomInfo.label)
                            .focused($isInputActive)
                            .onAppear {
                                if customInfo == nil {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                        isInputActive = true
                                    }
                                }
                            }
                    }
                    
                    LabeledInput(label: "Detail") {
                        TextField("ABC 123", text: $draftCustomInfo.detail)
                    }
                }
                
                Section("Note") {
                    TextEditor(text: $draftCustomInfo.note)
                }
                
                Section(header: AddPhotoButton(photos: $draftCustomInfo.photos)) {
                    EditablePhotoGridView(photos: $draftCustomInfo.photos)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(customInfo != nil ? "Edit Info" : "New Info")
            .navigationBarTitleDisplayMode(.inline)
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
