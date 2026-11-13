//
//  AddEditRecordView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI
import TipKit

struct AddEditRecordView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Observed Objects
    @ObservedObject var service: Service
    
    // MARK: - State
    @StateObject var draftServiceLog = DraftServiceLog()
    @FocusState private var focusedField: Field?
    @State private var didSetInitialFocus = false
    @State private var showingDeleteAlert = false
    @State private var odometerWarning: OdometerWarning?
    @State private var showingSelectedServices = false
    
    // MARK: - Input
    private let vehicle: Vehicle
    private let record: ServiceRecord?
    private let onDelete: (() -> Void)?
    
    // MARK: - Init
    init(service: Service? = nil, services: [Service] = [], vehicle: Vehicle, record: ServiceRecord? = nil, onDelete: (() -> Void)? = nil) {
        let preselectedServices = services.isEmpty ? [service].compactMap { $0 } : services

        self.service = service ?? services.first ?? Service(context: DataController.shared.container.viewContext)
        self.vehicle = vehicle
        self.record = record
        self.onDelete = onDelete
        
        _draftServiceLog = StateObject(wrappedValue: DraftServiceLog(record: record, preselectedServices: preselectedServices))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                FormHeaderView(symbolName: AppSection.maintenance.symbol(filled: true), primaryText: record != nil ? "Edit Service Log" : "New Service Log", accentColor: AppSection.maintenance.color)
                
                Section {
                    DatePicker("Service Date", selection: $draftServiceLog.date, displayedComponents: .date)
                    
                    if let record, record.serviceLog == nil {
                        // If a pre-2.0 record exists, don't show SelectedServicesListview (doesn't save selection)
                        LabeledInput(label: "Service Performed") {
                            Text(service.name)
                        }
                    } else {
                        Button(action: showSelectedServices) {
                            LabeledContent("Services Performed") {
                                FormLinkLabel {
                                    Group {
                                        if draftServiceLog.selectedServiceIDs.isEmpty {
                                            Text("Select")
                                                .foregroundStyle(.tertiary)
                                        } else {
                                            Text(draftServiceLog.selectedServiceNames(from: vehicle))
                                        }
                                    }
                                    .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                        .accessibilityHint("Opens selected services list")
                    }
                    
                    LabeledInput(label: "Odometer") {
                        NumericInput("Required", value: $draftServiceLog.odometer, focus: $focusedField, field: .odometer)
                    }
                    
                    LabeledInput(label: "Cost") {
                        NumericInput("Optional", value: $draftServiceLog.cost.zeroAsNil, focus: $focusedField, field: .cost)
                    }
                }
                
                FormFooterView (
                    note: $draftServiceLog.note,
                    photos: $draftServiceLog.photos,
                    documents: $draftServiceLog.documents,
                    deleteButtonTitle: "Delete Service Log",
                    focusedField: $focusedField,
                    noteField: .note,
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .listRowSpacing(0) // Added to prevent list row spacing when launched from swipe action on MaintenanceListView
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingSelectedServices, destination: {
                SelectedServicesListView(draftServiceLog: draftServiceLog, vehicle: vehicle)
            })
            .keyboardToolbar(
                isFocused: focusedField != nil,
                canMovePrevious: focusedField != .odometer,
                canMoveNext: focusedField != .note,
                onPrevious: focusPreviousField,
                onNext: focusNextField,
                onDone: { focusedField = nil }
            )
            .task {
                guard record == nil && !draftServiceLog.selectedServiceIDs.isEmpty, !didSetInitialFocus else { return }
                didSetInitialFocus = true

                await Task.yield()
                guard !Task.isCancelled else { return }

                focusedField = .odometer
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(record != nil ? "Done" : "Add", systemImage: "checkmark") {
                        focusedField = nil
                        saveRecord()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftServiceLog.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        focusedField = nil
                        dismiss()
                    }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }
            }
            .tint(AppSection.maintenance.color)
            .alert("Delete Record", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    focusedField = nil
                    if let record {
                        DataController.shared.delete(record)
                    }
                    
                    dismiss()
                    onDelete?()
                }
                Button("Cancel", role: .cancel) { focusedField = nil }
            } message: {
                Text("Permanently delete this service log? This cannot be undone.")
            }
            .odometerWarningAlert(
                warning: $odometerWarning,
                entered: draftServiceLog.odometer,
                current: vehicle.odometer,
                distanceUnit: vehicle.distanceUnit.abbreviated,
                onConfirm: performRecordSave
            )
        }
        .tint(nil)
    }
    
    private enum Field: Hashable {
        case odometer, cost, note
    }
    
    private func focusPreviousField() {
        switch focusedField {
        case .cost:
            focusedField = .odometer
        case .note:
            focusedField = .cost
        default:
            break
        }
    }
    
    private func focusNextField() {
        switch focusedField {
        case .odometer:
            focusedField = .cost
        case .cost:
            focusedField = .note
        default:
            break
        }
    }
    
    private func showSelectedServices() {
        focusedField = nil
        
        // Allow keyboard dismissal to begin before pushing the Services screen.
        DispatchQueue.main.async {
            showingSelectedServices = true
        }
    }

    private func saveRecord() {
        if let entered = draftServiceLog.odometer,
           let warning = OdometerValidator.warning(
               entered: entered,
               current: vehicle.odometer,
               context: .historicalRecord
           ) {
            odometerWarning = warning
            return
        }

        performRecordSave()
    }

    private func performRecordSave() {
        if let record {
            if let log = record.serviceLog {
                log.updateAndSave(draftServiceLog: draftServiceLog, allServices: vehicle.sortedServicesArray)
            } else {
                record.updateAndSave(service: service, draftServiceLog: draftServiceLog)
            }
        } else {
            service.addNewServiceRecord(draftServiceLog: draftServiceLog, allServices: vehicle.sortedServicesArray)
        }

        dismiss()
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    
    let service = Service(context: context)
    service.name = "Oil Change"
    
    let record = ServiceRecord(context: context)
    record.odometer = 12345
    
    return AddEditRecordView(service: service, vehicle: vehicle, record: record)
}
