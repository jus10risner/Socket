//
//  AddRecordView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddRecordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftServiceRecord = DraftServiceRecord()
    @ObservedObject var vehicle: Vehicle
    let service: Service
    
    init(vehicle: Vehicle, service: Service) {
        self.vehicle = vehicle
        self.service = service
        
        _draftServiceRecord = StateObject(wrappedValue: DraftServiceRecord())
    }
    
    var body: some View {
        AppropriateNavigationType {
            VStack(spacing: 0) {
                Text(service.name)
                    .foregroundStyle(Color.secondary)
                
                DraftServiceRecordView(draftServiceRecord: draftServiceRecord, isEditView: false)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Service Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        service.addNewServiceRecord(vehicle: vehicle, draftServiceRecord: draftServiceRecord)
                        
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
    AddRecordView(vehicle: Vehicle(context: DataController.preview.container.viewContext), service: Service(context: DataController.preview.container.viewContext))
}
