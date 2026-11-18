//
//  AddEditVehicleView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import CoreData
import SwiftUI

struct AddEditVehicleView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @StateObject var draftVehicle = DraftVehicle()
    private let vehicle: Vehicle?
    private let onDelete: (() -> Void)?
    
    init(vehicle: Vehicle? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.onDelete = onDelete
        _draftVehicle = StateObject(wrappedValue: DraftVehicle(vehicle: vehicle))
    }
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @FocusState private var focusedField: Field?
    @State private var didSetInitialFocus = false
    @State private var showingDuplicateNameError = false
    @State private var showingDeleteAlert = false
    @State private var showingMeasurementMigrationAlert = false
    @State private var showingSaveError = false
    @State private var odometerWarning: OdometerWarning?
    @State private var showingUnitsSelection = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AddEditVehicleImageView(draftVehicle: draftVehicle, onButtonTap: { focusedField = nil })
                        .listRowInsets(EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1))
                        .listRowBackground(Color.clear)
                }
                
                Section {
                    LabeledInput(label: "Vehicle Name") {
                        TextField("Required", text: $draftVehicle.name)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .name)
                            .selectAllOnFocus()
                    }
                    
                    LabeledInput(label: "Odometer") {
                        NumericInput("Required", value: $draftVehicle.odometer, focus: $focusedField, field: .odometer)
                    }
                }
                
                Section {
                    Button(action: showUnitsSelection) {
                        LabeledContent("Units") {
                            FormLinkLabel {
                                Text(unitDescription)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    .accessibilityHint("Opens measurement unit settings")
                }
                
                if vehicle != nil {
                    Button("Delete Vehicle", role: .destructive) {
                        focusedField = nil
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle(vehicle != nil ? "Edit Vehicle" : "New Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(isPresented: $showingUnitsSelection) {
                VehicleUnitsView(draftVehicle: draftVehicle)
            }
            .keyboardToolbar(
                isFocused: focusedField != nil,
                canMovePrevious: focusedField != .name,
                canMoveNext: focusedField != .odometer,
                onPrevious: { focusedField = .name },
                onNext: { focusedField = .odometer },
                onDone: { focusedField = nil }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        focusedField = nil
                        dismiss()
                    }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(vehicle != nil ? "Done" : "Add", systemImage: "checkmark") {
                        focusedField = nil
                        saveVehicle()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftVehicle.canBeSaved ? false : true)
                }
            }
            .alert("You already have a vehicle with that name", isPresented: $showingDuplicateNameError) {
                Button("OK", role: .cancel) { focusedField = nil }
            } message: {
                Text("Please choose a different name.")
            }
            .alert("Delete Vehicle", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    focusedField = nil
                    if let vehicle = vehicle {
                        DataController.shared.delete(vehicle)
                    }
                    
                    dismiss()
                    
                    // Dismisses VehicleDashboardView, after a short delay, to avoid jumping immediately back to VehicleListView
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onDelete?()
                    }
                }
                Button("Cancel", role: .cancel) { focusedField = nil }
            } message: {
                Text("Permanently delete this vehicle and all of its records? This action cannot be undone.")
            }
            .alert("Update Units?", isPresented: $showingMeasurementMigrationAlert) {
                Button("Update") {
                    focusedField = nil
                    performVehicleSave()
                }
                Button("Cancel", role: .cancel) { focusedField = nil }
            } message: {
                Text("Make sure your other devices are running iOS 18.5 or later with the latest version of Socket. Older versions may display this vehicle’s data incorrectly after updating.")
            }
            .alert("Unable to Save Changes", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { focusedField = nil }
            } message: {
                Text("Your changes were not saved. Please try again.")
            }
            .odometerWarningAlert(
                warning: $odometerWarning,
                entered: draftVehicle.odometer,
                current: currentOdometerInSelectedUnit,
                distanceUnit: draftVehicle.distanceUnit.abbreviated,
                onConfirm: confirmMeasurementMigrationIfNeeded
            )
        }
        .tint(nil)
    }
    
    
    // MARK: - Computed Properties
    
    private enum Field: Hashable {
        case name, odometer
    }
    
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

    private var currentOdometerInSelectedUnit: Int? {
        guard let vehicle else { return nil }

        let sourceUnit = vehicle.usesCanonicalMeasurements
            ? vehicle.distanceUnit
            : draftVehicle.legacyDistanceUnit
        let kilometers = MeasurementConverter.kilometers(
            from: Double(vehicle.odometer),
            unit: sourceUnit
        )

        return Int(MeasurementConverter.distance(
            fromKilometers: kilometers,
            unit: draftVehicle.distanceUnit
        ).rounded())
    }
    
    private var unitDescription: String {
        let distance = draftVehicle.distanceUnit.rawValue.capitalized
        let volume = draftVehicle.volumeUnit == .liters ? "Liters" : "Gallons"

        return "\(distance), \(volume), \(draftVehicle.fuelEconomyUnit.settingsName)"
    }
    
    
    // MARK: - Methods

    private func showUnitsSelection() {
        focusedField = nil

        // Allow keyboard dismissal to begin before pushing the Units screen.
        DispatchQueue.main.async {
            showingUnitsSelection = true
        }
    }

    private func saveVehicle() {
        guard !vehicles.contains(where: { $0.name == draftVehicle.name && $0.id != vehicle?.id }) else {
            showingDuplicateNameError = true
            return
        }

        if let vehicle, let entered = draftVehicle.odometer,
           let warning = OdometerValidator.warning(
               entered: entered,
               current: currentOdometerInSelectedUnit ?? vehicle.odometer,
               context: .currentVehicle
           ) {
            odometerWarning = warning
            return
        }

        confirmMeasurementMigrationIfNeeded()
    }

    private func confirmMeasurementMigrationIfNeeded() {
        if vehicle?.usesCanonicalMeasurements == false, draftVehicle.shouldMigrateMeasurements {
            showingMeasurementMigrationAlert = true
        } else {
            performVehicleSave()
        }
    }

    private func performVehicleSave() {
        let didSave: Bool

        if let vehicle {
            didSave = vehicle.updateAndSave(draftVehicle: draftVehicle)
        } else {
            didSave = addNewVehicle()
        }

        if didSave {
            dismiss()
        } else {
            DispatchQueue.main.async {
                showingSaveError = true
            }
        }
    }
    
    // Creates a new vehicle object, using the information from this view
    func addNewVehicle() -> Bool {
        let colorComponents = UIColor(draftVehicle.selectedColor).cgColor.components
        
        let newVehicle = Vehicle(context: context)
        newVehicle.id = UUID()
        newVehicle.name = draftVehicle.name
        newVehicle.distanceUnit = draftVehicle.distanceUnit
        newVehicle.volumeUnit = draftVehicle.volumeUnit
        newVehicle.fuelEconomyUnit = draftVehicle.fuelEconomyUnit
        newVehicle.markMeasurementsAsCanonical()
        newVehicle.odometer = draftVehicle.odometer ?? 0
        newVehicle.recordOdometerActivity()
        newVehicle.colorComponents = colorComponents
        newVehicle.photo = draftVehicle.photo
        newVehicle.displayOrder = newVehicleDisplayOrder
        
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            print("⚠️ Failed to add vehicle: \(error.localizedDescription)")
            return false
        }
    }
}

private struct VehicleUnitsView: View {
    @ObservedObject var draftVehicle: DraftVehicle

    var body: some View {
        Form {
            Section {
                Picker("Distance", selection: displayDistanceUnit) {
                    ForEach(DistanceUnits.allCases, id: \.self) { unit in
                        Text(unit.rawValue.capitalized).tag(unit)
                    }
                }

                Picker("Fuel Volume", selection: $draftVehicle.volumeUnit) {
                    ForEach(VolumeUnits.allCases, id: \.self) { unit in
                        Text(unit.settingsName).tag(unit)
                    }
                }

                Picker("Fuel Economy", selection: $draftVehicle.fuelEconomyUnit) {
                    ForEach(FuelEconomyUnits.allCases, id: \.self) { unit in
                        Text(unit.settingsName)
                            .tag(unit)
                            .accessibilityLabel(unit.fullName)
                    }
                }
            }

            if draftVehicle.shouldMigrateMeasurements {
                Section {
                    Picker("Distance", selection: $draftVehicle.legacyDistanceUnit) {
                        ForEach(DistanceUnits.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }

                    Picker("Fuel Volume", selection: $draftVehicle.legacyVolumeUnit) {
                        ForEach(VolumeUnits.allCases, id: \.self) { unit in
                            Text(unit.settingsName).tag(unit)
                        }
                    }
                } header: {
                    Text("Please confirm the units used for this vehicle’s existing records so Socket can safely convert them to your preferred units.")
                        .font(.body)
                }
                .textCase(nil)
            }
        }
        .animation(.default, value: draftVehicle.shouldMigrateMeasurements)
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var displayDistanceUnit: Binding<DistanceUnits> {
        Binding {
            draftVehicle.distanceUnit
        } set: {
            draftVehicle.setDistanceUnit($0)
        }
    }
}

#Preview {
    AddEditVehicleView()
}
