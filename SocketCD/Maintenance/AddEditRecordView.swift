//
//  AddEditRecordView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditRecordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @StateObject var draftServiceRecord = DraftServiceRecord()
    @ObservedObject var service: Service
    let record: ServiceRecord?
    var onDelete: (() -> Void)?
    
    init(service: Service, record: ServiceRecord? = nil, onDelete: (() -> Void)? = nil) {
        self.service = service
        self.record = record
        self.onDelete = onDelete
        
        _draftServiceRecord = StateObject(wrappedValue: DraftServiceRecord(record: record))
    }
    
    @State private var showingDeleteAlert = false
    
    @FocusState var isInputActive: Bool
    @FocusState var fieldInFocus: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(service.name)
                    .padding(.horizontal, 10)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)
                
                Form {
                    Section {
                        DatePicker("Service Date", selection: $draftServiceRecord.date, displayedComponents: .date)
                            .foregroundStyle(Color.secondary)
                        
                        LabeledInput(label: "Odometer") {
                            TextField("Required", value: $draftServiceRecord.odometer, format: .number.decimalSeparator(strategy: .automatic))
                                .keyboardType(.numberPad)
                                .focused($fieldInFocus)
                                .onAppear {
                                    if record == nil {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                            fieldInFocus = true
                                        }
                                    }
                                }
                        }
                        
                        LabeledInput(label: "Cost") {
                            TextField("Optional", value: $draftServiceRecord.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .keyboardType(.decimalPad)
                        }
                    }
                    .focused($isInputActive)
                    
                    FormFooterView (
                        note: $draftServiceRecord.note,
                        photos: $draftServiceRecord.photos,
                        onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                    )
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(record != nil ? "Edit Service Record" : "New Service Record")
            .navigationBarTitleDisplayMode(.inline)
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
