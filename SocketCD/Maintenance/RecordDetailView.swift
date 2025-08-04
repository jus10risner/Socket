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
    @State private var showingDeleteAlert = false
    
    var body: some View {
        recordDetails
    }
    
    // MARK: - Views
    
    private var recordDetails: some View {
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
                Menu {
                    Button {
                        showingEditRecord = true
                    } label: {
                        Label("Edit Record", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Record", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Service Record Options")
                }
            }
        }
        .sheet(isPresented: $showingEditRecord) {
            AddEditRecordView(service: service, record: record)
        }
        .alert("Delete Record", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
//                record.delete(for: service)
                DataController.shared.delete(record)
                
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Permanently delete this service record? This cannot be undone.")
        }
    }
}

#Preview {
    RecordDetailView(record: ServiceRecord(context: DataController.preview.container.viewContext), vehicle: Vehicle(context: DataController.preview.container.viewContext), service: Service(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
