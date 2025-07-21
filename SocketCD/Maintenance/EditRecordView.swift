//
//  EditRecordView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct EditRecordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftServiceRecord = DraftServiceRecord()
//    @ObservedObject var vehicle: Vehicle
    @ObservedObject var service: Service
    var record: ServiceRecord
    
    init(service: Service, record: ServiceRecord) {
//        self.vehicle = vehicle
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Service Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        record.updateAndSave(service: service, draftServiceRecord: draftServiceRecord)
                        
                        dismiss()
                    }
                    .disabled(draftServiceRecord.canBeSaved ? false : true)
                }
            }
        }
    }
}

#Preview {
    EditRecordView(service: Service(context: DataController.preview.container.viewContext), record: ServiceRecord(context: DataController.preview.container.viewContext))
}
