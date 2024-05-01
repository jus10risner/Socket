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
                // Using HStack, because iOS 15 doesn't show badge text at all, if Text("").badge("") is used
                HStack {
                    Text("Date")
                    
                    Spacer()
                    
                    Text(record.date.formatted(date: .numeric, time: .omitted))
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityElement(children: .combine)
                
                HStack {
                    Text("Odometer")
                    
                    Spacer()
                    
                    Text("\(record.odometer.formatted()) \(settings.shortenedDistanceUnit)")
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityElement(children: .combine)
                
                HStack {
                    Text("Cost")
                    
                    Spacer()
                    
                    Text(vehicle.convertToCurrency(value: record.cost ?? 0))
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityElement(children: .combine)
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
//        .navigationBarTitleDisplayMode(.inline)
//        .modifier(CustomNavigationTitleDisplayMode())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
            EditRecordView(vehicle: vehicle, service: service, record: record)
        }
        .alert("Delete Record", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                record.delete()
                
                // Cancels pending notifications, if the last record is deleted
                if service.sortedServiceRecordsArray.isEmpty {
                    service.cancelPendingNotifications()
                }
                
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\nPermanently delete this service record? This cannot be undone.")
        }
    }
}

#Preview {
    RecordDetailView(record: ServiceRecord(context: DataController.preview.container.viewContext), vehicle: Vehicle(context: DataController.preview.container.viewContext), service: Service(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
