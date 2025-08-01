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
    @ObservedObject var repair: Repair
    
    @State private var showingEditRepair = false
    
    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: repair.date.formatted(date: .numeric, time: .omitted))
                
                LabeledContent("Name", value: repair.name)
                
                LabeledContent("Odometer") {
                    Text("\(repair.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                }
                
                LabeledContent("Cost", value: (repair.cost ?? 0).asCurrency())
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
                Button("Edit") {
                    showingEditRepair = true
                }
            }
        }
        .sheet(isPresented: $showingEditRepair) {
            AddEditRepairView(repair: repair, onDelete: {
                dismiss()
            })
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    
    RepairDetailView(repair: Repair(context: context))
        .environmentObject(AppSettings())
}
