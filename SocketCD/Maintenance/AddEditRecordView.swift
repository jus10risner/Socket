//
//  AddEditRecordView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditRecordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftServiceRecord = DraftServiceRecord()
    @ObservedObject var vehicle: Vehicle
    @ObservedObject var service: Service
    var record: ServiceRecord?
    
    init(vehicle: Vehicle, service: Service, record: ServiceRecord? = nil) {
        self.vehicle = vehicle
        self.service = service
        self.record = record
        
        _draftServiceRecord = StateObject(wrappedValue: DraftServiceRecord(record: record))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(service.name)
                    .padding(.horizontal, 10)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)
                
                DraftServiceRecordView(draftServiceRecord: draftServiceRecord, isEditView: true)
            }
            .navigationTitle(record != nil ? "Edit Service Record" : "New Service Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let record {
                            record.updateAndSave(service: service, draftServiceRecord: draftServiceRecord)
                        } else {
                            service.addNewServiceRecord(vehicle: vehicle, draftServiceRecord: draftServiceRecord)
                        }
                        
                        dismiss()
                    }
                    .disabled(draftServiceRecord.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    
    return AddEditRecordView(vehicle: Vehicle(context: context), service: Service(context: context), record: ServiceRecord(context: context))
        .environmentObject(AppSettings())
}
