//
//  AddEditFillupView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditFillupView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    let settings = AppSettings.shared
    
    // MARK: - State
    @StateObject var draftFillup = DraftFillup()
    @FocusState var isInputActive: Bool
    @State var showingFillTypeInfo = false
    @State private var showingDeleteAlert = false
    
    // MARK: - Input
    private let vehicle: Vehicle?
    private let fillup: Fillup?
    private let onDelete: (() -> Void)?
    
    // MARK: - Init
    init(vehicle: Vehicle? = nil, fillup: Fillup? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.fillup = fillup
        self.onDelete = onDelete
        
        if let fillup {
            _draftFillup = StateObject(wrappedValue: DraftFillup(fillup: fillup))
        } else {
            _draftFillup = StateObject(wrappedValue: DraftFillup())
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                FormHeaderView(symbolName: "fuelpump.fill", primaryText: fillup != nil ? "Edit Fill-up" : "New Fill-up", accentColor: Color.fillupsTheme)
                
                Section {
                    DatePicker("Fill-up Date", selection: $draftFillup.date, displayedComponents: .date)
                        .foregroundStyle(Color.secondary)
                    
                    LabeledInput(label: "Odometer") {
                        TextField("Required", value: $draftFillup.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                            .focused($isInputActive)
                    }
                    
                    LabeledInput(label: "\(settings.fuelEconomyUnit.volumeUnit)s of Fuel") {
                        TextField("Required", value: $draftFillup.volume, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.decimalPad)
                    }
                    
                    LabeledContent {
                        TextField("Optional", value: $draftFillup.cost, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.decimalPad)
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.trailing)
                    } label: {
                        Text(settings.fillupCostType == .perUnit ? "Price per \(settings.fuelEconomyUnit.volumeUnit)" : "Total Cost")
                        
                        if settings.showCalculatedCost {
                            Text(settings.fillupCostType == .perUnit ? "Total: \(calculatedCost)" : "Per \(settings.fuelEconomyUnit.volumeUnit): \(calculatedCost)")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(Color.secondary)
                    
                    fillTypePicker
                } footer: {
                    Button("About fill types...") { showingFillTypeInfo = true }
                        .font(.footnote)
                }
                
                FormFooterView (
                    note: $draftFillup.note,
                    photos: $draftFillup.photos,
                    deleteButtonTitle: "Delete Fill-up",
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showingFillTypeInfo) { FillTypeInfoView() }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if fillup == nil {
                    // Show keyboard automatically, when adding a new fill-up
                    DispatchQueue.main.async {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(fillup != nil ? "Done" : "Add", systemImage: "checkmark") {
                        if let fillup {
                            fillup.updateAndSave(draftFillup: draftFillup)
                        } else if let vehicle {
                            vehicle.addNewFillup(draftFillup: draftFillup)
                        }
                        
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftFillup.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }
            }
            .alert("Delete Fill-up", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let fillup {
                        DataController.shared.delete(fillup)
                    }
                    
                    dismiss()
                    onDelete?()
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Deleting fill-up records may cause inaccurate fuel economy calculation. Delete this record anyway?")
            }
        }
    }
    
    // Returns the total or per-unit cost, based on which the user has selected in settings (used to show both costs at once)
    private var calculatedCost: String {
        guard let cost = draftFillup.cost else { return 0.0.asCurrency() }
        
        if settings.fillupCostType == .perUnit {
            return (cost * (draftFillup.volume ?? 0)).asCurrency()
        } else {
            return (cost / (draftFillup.volume ?? 0)).asCurrency()
        }
    }
    
    // Allows the user to specify a fill type for a given fill-up
    private var fillTypePicker: some View {
        LabeledInput(label: "Fill Type") {
            Picker("Select a Fill Type", selection: $draftFillup.fillType) {
                ForEach(FillType.allCases, id: \.self) { fillupType in
                    Text(fillupType.rawValue)
                }
            }
            .labelsHidden()
        }
        .buttonStyle(.plain)
        .tint(Color.primary)
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    let fillup = Fillup(context: context)
    
    return AddEditFillupView(vehicle: vehicle, fillup: fillup)
}
