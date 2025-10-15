//
//  AddEditRepairView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct AddEditRepairView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @StateObject var draftRepair = DraftRepair()
    @FocusState var isInputActive: Bool
    @State private var showingDeleteAlert = false
    
    // MARK: - Input
    private let vehicle: Vehicle?
    private let repair: Repair?
    private let onDelete: (() -> Void)?
    
    // MARK: - Init
    init(vehicle: Vehicle? = nil, repair: Repair? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.repair = repair
        self.onDelete = onDelete
        
        _draftRepair = StateObject(wrappedValue: DraftRepair(repair: repair))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $draftRepair.date, displayedComponents: .date)
                        .foregroundStyle(Color.secondary)
                    
                    LabeledInput(label: "Name") {
                        TextField("Required", text: $draftRepair.name)
                            .textInputAutocapitalization(.words)
                            .focused($isInputActive)
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
                
                FormFooterView (
                    note: $draftRepair.note,
                    photos: $draftRepair.photos,
                    deleteButtonTitle: "Delete Repair",
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(repair != nil ? "Edit Repair" : "New Repair")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if repair == nil {
                    // Show keyboard after a short delay, when adding a new repair
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(repair != nil ? "Done" : "Add", systemImage: "checkmark") {
                        if let repair {
                            repair.updateAndSave(draftRepair: draftRepair)
                        } else if let vehicle {
                            vehicle.addNewRepair(draftRepair: draftRepair)
                        }
                        
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftRepair.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
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
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    let repair = Repair(context: context)
    
    return AddEditRepairView(vehicle: vehicle, repair: repair)
}
