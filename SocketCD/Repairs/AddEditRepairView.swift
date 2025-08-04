//
//  AddEditRepairView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct AddEditRepairView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftRepair = DraftRepair()
    let vehicle: Vehicle?
    let repair: Repair?
    var onDelete: (() -> Void)?
    
    init(vehicle: Vehicle? = nil, repair: Repair? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.repair = repair
        self.onDelete = onDelete
        
        _draftRepair = StateObject(wrappedValue: DraftRepair(repair: repair))
    }
    
    @FocusState var isInputActive: Bool
    @FocusState var fieldInFocus: Bool
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $draftRepair.date, displayedComponents: .date)
                        .foregroundStyle(Color.secondary)
                    
                    LabeledInput(label: "Name") {
                        TextField("Required", text: $draftRepair.name, axis: .vertical)
                            .textInputAutocapitalization(.words)
                            .focused($fieldInFocus)
                            .onAppear {
                                if repair == nil {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                        fieldInFocus = true
                                    }
                                }
                            }
                    }
                    
                    LabeledInput(label: "Odometer") {
                        TextField("Required", value: $draftRepair.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                    }
                    
                    LabeledInput(label: "Cost") {
                        TextField("Optional", value: $draftRepair.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
                .focused($isInputActive)
                
                Section("Note") {
                    TextEditor(text: $draftRepair.note)
                        .frame(minHeight: 50)
                        .focused($isInputActive)
                }
                
                Section(header: AddPhotoButton(photos: $draftRepair.photos)) {
                    EditablePhotoGridView(photos: $draftRepair.photos)
                }
                
                if onDelete != nil {
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(repair != nil ? "Edit Repair" : "New Repair")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let repair {
                            repair.updateAndSave(draftRepair: draftRepair)
                        } else if let vehicle {
                            vehicle.addNewRepair(draftRepair: draftRepair)
                        }
                        
                        dismiss()
                    }
                    .disabled(draftRepair.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .alert("Delete Repair", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let repair {
                        DataController.shared.delete(repair)
                    }
                    
                    dismiss()
                    onDelete?()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Permanently delete this repair record? This cannot be undone.")
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    
    AddEditRepairView(vehicle: Vehicle(context: context), repair: Repair(context: context))
}
