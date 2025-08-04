//
//  RecordDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct RecordDetailView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    @ObservedObject var record: ServiceRecord
    let vehicle: Vehicle
    let service: Service
    
    @State private var showingEditRecord = false
    
    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: record.date.formatted(date: .numeric, time: .omitted))
                
                LabeledContent("Odometer") {
                    Text("\(record.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                }
                
                LabeledContent("Cost", value: (record.cost ?? 0).asCurrency())
            }
            
            if record.note != "" {
                Section("Note") {
                    Text(record.note)
                }
            }
            
            if !record.sortedPhotosArray.isEmpty {
                PhotoGridView(photos: record.sortedPhotosArray)
            }
        }
        .navigationTitle("Record Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditRecord = true
                }
            }
        }
        .sheet(isPresented: $showingEditRecord) {
            AddEditRecordView(service: service, record: record) {
                dismiss()
            }
        }
    }
}

#Preview {
    RecordDetailView(record: ServiceRecord(context: DataController.preview.container.viewContext), vehicle: Vehicle(context: DataController.preview.container.viewContext), service: Service(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
