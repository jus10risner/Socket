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
    let settings = AppSettingsStore.shared
    
    // MARK: - State
    @StateObject var draftFillup = DraftFillup()
    @FocusState var isInputActive: Bool
    @State var showingFillTypeInfo = false
    @State private var showingDeleteAlert = false
    @State private var showingDuplicateOdometerError = false
    @State private var odometerWarning: OdometerWarning?
    
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
                FormHeaderView(symbolName: AppSection.fillups.symbol(filled: true), primaryText: fillup != nil ? "Edit Fill-up" : "New Fill-up", accentColor: AppSection.fillups.color)
                
                Section {
                    DatePicker("Fill-up Date", selection: $draftFillup.date, displayedComponents: .date)
                        .foregroundStyle(Color.secondary)
                    
                    LabeledInput(label: "Odometer") {
                        TextField("Required", value: $draftFillup.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                            .focused($isInputActive)
                    }
                    
                    LabeledInput(label: "\(volumeUnit.singularName)s of Fuel") {
                        TextField(
                            "Required",
                            value: $draftFillup.volume,
                            format: .number
                                .precision(.fractionLength(0...3))
                                .decimalSeparator(strategy: .automatic)
                        )
                            .keyboardType(.decimalPad)
                    }
                    
                    LabeledContent {
                        TextField("Optional", value: $draftFillup.cost, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.decimalPad)
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.trailing)
                    } label: {
                        Group {
                            Text(settings.fillupCostType == .perUnit ? "Cost per \(volumeUnit.singularName)" : "Total Cost")
                            
                            if settings.showCalculatedCost {
                                Text(settings.fillupCostType == .perUnit ? "Total: \(calculatedCost)" : "Per \(volumeUnit.singularName): \(calculatedCost)")
                                    .font(.caption)
                            }
                        }
                        .accessibilityHidden(true)
                    }
                    .foregroundStyle(Color.secondary)
                    .accessibilityLabel(settings.fillupCostType == .perUnit ? "Cost per \(volumeUnit.singularName)" : "Total Cost")
                    .accessibilityHint(
                        settings.showCalculatedCost && draftFillup.cost != nil
                        ? (settings.fillupCostType == .perUnit
                           ? "Total cost for this fill-up: \(calculatedCost)"
                           : "Cost per \(volumeUnit.singularName) for this fill-up: \(calculatedCost)")
                        : ""
                    )
                    
                    
                    fillTypePicker
                } footer: {
                    Button("About fill types...") {
                        isInputActive = false
                        showingFillTypeInfo = true
                    }
                    .font(.footnote)
                    .accessibilityLabel("About fill types")
                }
                
                FormFooterView (
                    note: $draftFillup.note,
                    photos: $draftFillup.photos,
                    documents: $draftFillup.documents,
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
                        saveFillup()
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
            .tint(AppSection.fillups.color)
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
            .alert(
                "Odometer reading already used",
                isPresented: $showingDuplicateOdometerError
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Each fill-up needs a different odometer reading.")
            }
            .odometerWarningAlert(
                warning: $odometerWarning,
                entered: draftFillup.odometer,
                current: comparisonVehicle?.odometer,
                distanceUnit: distanceUnit.abbreviated,
                onConfirm: performFillupSave
            )
        }
        .tint(nil)
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

    private var hasDuplicateOdometer: Bool {
        guard let odometer = draftFillup.odometer,
              let vehicle = vehicle ?? fillup?.vehicle else {
            return false
        }

        return vehicle.sortedFillupsArray.contains { existingFillup in
            existingFillup.odometer == odometer
                && existingFillup.objectID != fillup?.objectID
        }
    }

    private var comparisonVehicle: Vehicle? {
        vehicle ?? fillup?.vehicle
    }

    private var distanceUnit: DistanceUnits {
        comparisonVehicle?.distanceUnit ?? settings.distanceUnit
    }

    private var volumeUnit: VolumeUnits {
        comparisonVehicle?.volumeUnit ?? settings.volumeUnit
    }

    // Allows the user to specify a fill type for a given fill-up
    private var fillTypePicker: some View {
        LabeledInput(label: "Fill Type") {
            Picker("", selection: $draftFillup.fillType) {
                ForEach(FillType.allCases, id: \.self) { fillupType in
                    Text(fillupType.rawValue)
                }
            }
            .labelsHidden()
        }
        .buttonStyle(.plain)
        .tint(Color.primary)
    }

    private func saveFillup() {
        guard !hasDuplicateOdometer else {
            showingDuplicateOdometerError = true
            return
        }

        if let entered = draftFillup.odometer, let comparisonVehicle,
           let warning = OdometerValidator.warning(
               entered: entered,
               current: comparisonVehicle.odometer,
               context: .historicalRecord
           ) {
            odometerWarning = warning
            return
        }

        performFillupSave()
    }

    private func performFillupSave() {

        if let fillup {
            fillup.updateAndSave(draftFillup: draftFillup)
        } else if let vehicle {
            vehicle.addNewFillup(draftFillup: draftFillup)
        }

        dismiss()
    }
}

// MARK: - Subviews

private struct FillTypeInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Full Tank")
                            .font(.headline)
                        
                        Text("Select this fill type if you have filled your fuel tank completely. To track fuel economy accurately, it is important to always try to use Full Tank fill-ups.")
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Partial Fill")
                            .font(.headline)
                        
                        Text("Select this fill type if fuel was added, but the fuel tank is not completely full. Fuel economy will not be calculated for this fill-up, but will resume after your next Full Tank fill-up.")
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Missed Fill-up (Full Tank)")
                            .font(.headline)
                        
                        Text("Select this fill type if you forgot to add one or more recent fill-ups to Socket. Fuel economy calculation will resume after your next Full Tank fill-up.")
                        
                        Text("**Note:** Only select this fill type if your fuel tank is full. If not, please wait until your next Full Tank fill-up to begin adding fill-ups to Socket again.")
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .font(.subheadline)
            .navigationTitle("Fill Types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done", systemImage: "xmark") {
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .adaptiveTint()
                }
            }
        }
        .onAppear() {
            // Dismisses keyboard
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
