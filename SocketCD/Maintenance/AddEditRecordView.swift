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
    @EnvironmentObject var settings: AppSettings
    
    // MARK: - Observed Objects
    @ObservedObject var service: Service
    
    // MARK: - State
    @StateObject var draftServiceRecord = DraftServiceRecord()
    @FocusState var isInputActive: Bool
    @State private var showingDeleteAlert = false
    
    // MARK: - Input
    private let record: ServiceRecord?
    private let onDelete: (() -> Void)?
    
    // MARK: - Init
    init(service: Service, record: ServiceRecord? = nil, onDelete: (() -> Void)? = nil) {
        self.service = service
        self.record = record
        self.onDelete = onDelete
        
        _draftServiceRecord = StateObject(wrappedValue: DraftServiceRecord(record: record))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Service Date", selection: $draftServiceRecord.date, displayedComponents: .date)
                        .foregroundStyle(Color.secondary)
                    
                    LabeledInput(label: "Odometer") {
                        TextField("Required", value: $draftServiceRecord.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                            .focused($isInputActive)
                    }
                    
                    LabeledInput(label: "Cost") {
                        TextField("Optional", value: $draftServiceRecord.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text(service.name)
                        .font(.body)
                        .frame(maxWidth: .infinity)
                }
                .headerProminence(.increased)
                
                FormFooterView (
                    note: $draftServiceRecord.note,
                    photos: $draftServiceRecord.photos,
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(record != nil ? "Edit Service Record" : "New Service Record")
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
                    Button("Done") {
                        if let record {
                            record.updateAndSave(service: service, draftServiceRecord: draftServiceRecord)
                        } else {
                            service.addNewServiceRecord(draftServiceRecord: draftServiceRecord)
                        }
                        
                        dismiss()
                    }
                    .disabled(draftServiceRecord.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .alert("Delete Record", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let record {
                        DataController.shared.delete(record)
                    }
                    
                    dismiss()
                    onDelete?()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Permanently delete this service record? This cannot be undone.")
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    
    return AddEditRecordView(service: Service(context: context), record: ServiceRecord(context: context))
        .environmentObject(AppSettings())
}
