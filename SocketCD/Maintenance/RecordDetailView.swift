//
//  RecordDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct RecordDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var record: ServiceRecord
    let settings = AppSettings.shared
    let vehicle: Vehicle
    let service: Service
    
    @State private var showingEditRecord = false
    
    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: record.effectiveDate.formatted(date: .numeric, time: .omitted))
                
                LabeledContent("Odometer") {
                    Text("\(record.effectiveOdometer.formatted()) \(settings.distanceUnit.abbreviated)")
                }
                
                LabeledContent("Cost", value: (record.effectiveCost ?? 0).asCurrency())
            }
            
            FormFooterView(note: record.effectiveNote, photos: record.effectivePhotos)
        }
        .navigationTitle("Log Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button("Edit") {
                    showingEditRecord = true
                }
                .adaptiveTint()
            }
        }
        .sheet(isPresented: $showingEditRecord) {
            AddEditRecordView(service: service, vehicle: vehicle, record: record) {
                dismiss()
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    
    let service = Service(context: context)
    service.name = "Oil Change"
    
    let record = ServiceRecord(context: context)
    record.odometer = 12345
    
    return RecordDetailView(record: record, vehicle: vehicle, service: service)
}
