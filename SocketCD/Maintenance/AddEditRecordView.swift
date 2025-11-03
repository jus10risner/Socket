//
//  AddEditRecordView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditRecordView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Observed Objects
    @ObservedObject var service: Service
    
    // MARK: - State
    @StateObject var draftServiceLog = DraftServiceLog()
    @FocusState var isInputActive: Bool
    @State private var showingDeleteAlert = false
    
    // MARK: - Input
    private let vehicle: Vehicle
    private let record: ServiceRecord?
    private let onDelete: (() -> Void)?
    
    // MARK: - Init
    init(service: Service? = nil, vehicle: Vehicle, record: ServiceRecord? = nil, onDelete: (() -> Void)? = nil) {
        self.service = service ?? Service(context: DataController.shared.container.viewContext)
        self.vehicle = vehicle
        self.record = record
        self.onDelete = onDelete
        
        _draftServiceLog = StateObject(wrappedValue: DraftServiceLog(record: record, preselectedService: service))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                AddEditFormSymbol(symbolName: "book.and.wrench.fill", text: record != nil ? "Edit Service Log" : "Log Service", accentColor: Color.maintenanceTheme)
                
                Section {
                    NavigationLink {
                        SelectedServicesListView(draftServiceLog: draftServiceLog, vehicle: vehicle)
                    } label: {
                        LabeledInput(label: "Services") {
                            Group {
                                if draftServiceLog.selectedServiceIDs.isEmpty {
                                    Text("Tap to Select")
//                                        .foregroundStyle(Color.secondary)
                                } else {
                                    Text(draftServiceLog.selectedServiceNames(from: vehicle))
                                }
                            }
                            .multilineTextAlignment(.leading)
                        }
                    }
                    
                    DatePicker("Service Date", selection: $draftServiceLog.date, displayedComponents: .date)
                        .foregroundStyle(Color.secondary)
                    
                    LabeledInput(label: "Odometer") {
                        TextField("Required", value: $draftServiceLog.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                            .focused($isInputActive)
                    }
                    
                    LabeledInput(label: "Cost") {
                        TextField("Optional", value: $draftServiceLog.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
                
                FormFooterView (
                    note: $draftServiceLog.note,
                    photos: $draftServiceLog.photos,
                    deleteButtonTitle: "Delete Service Log",
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .listRowSpacing(0) // Added to prevent list row spacing when launched from swipe action on MaintenanceListView
//            .navigationTitle(record != nil ? "Edit Service Log" : "Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if record == nil {
                    // Show keyboard after a short delay, when adding a new record
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(record != nil ? "Done" : "Add", systemImage: "checkmark") {
                        if let record {
                            if let log = record.serviceLog {
                                // Edit existing ServiceLog
                                log.updateAndSave(draftServiceLog: draftServiceLog, allServices: vehicle.sortedServicesArray)
                            } else {
                                // Edit legacy single ServiceRecord
                                record.updateAndSave(service: service, draftServiceLog: draftServiceLog)
                            }
                        } else {
                            // Add new record/log
                            service.addNewServiceRecord(draftServiceLog: draftServiceLog, allServices: vehicle.sortedServicesArray)
                        }
                        
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftServiceLog.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }
            }
            .alert("Delete Record", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let record {
                        service.cancelPendingNotifications()
                        DataController.shared.delete(record)
                    }
                    
                    dismiss()
                    onDelete?()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Permanently delete this service log? This cannot be undone.")
            }
        }
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
