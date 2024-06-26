//
//  RepairDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct RepairDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var vehicle: Vehicle
    @ObservedObject var repair: Repair
    
    @State private var showingEditRepair = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        repairDetail
    }
    
    
    // MARK: - Views
    
    private var repairDetail: some View {
        List {
            Section {
                Text("Date")
                    .badge(repair.date.formatted(date: .numeric, time: .omitted))
                
                // The .badge() modifier cuts off the Name text when the repair name is too long, so this accomodates long repair names
                HStack {
                    Text("Name")
                    
                    Spacer()
                    
                    Text(repair.name)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityElement(children: .combine)
                
                Text("Odometer")
                    .badge("\(repair.odometer.formatted()) \(settings.shortenedDistanceUnit)")
                
                Text("Cost")
                    .badge(vehicle.convertToCurrency(value: repair.cost ?? 0))
            }
            
            if repair.note != "" {
                Section("Note") {
                    Text(repair.note)
                }
            }
            
            if !repair.sortedPhotosArray.isEmpty {
                PhotoGridView(photos: repair.sortedPhotosArray)
            }
        }
        .navigationTitle("Repair Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditRepair = true
                    } label: {
                        Label("Edit Repair", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Repair", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Repair Options")
                }
            }
        }
        .sheet(isPresented: $showingEditRepair) {
            EditRepairView(vehicle: vehicle, repair: repair)
        }
        .alert("Delete Repair", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                repair.delete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\nPermanently delete this repair record? This cannot be undone.")
        }
    }
}

#Preview {
    RepairDetailView(vehicle: Vehicle(context: DataController.preview.container.viewContext), repair: Repair(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
