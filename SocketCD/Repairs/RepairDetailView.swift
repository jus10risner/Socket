//
//  RepairDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct RepairDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var repair: Repair
    let settings = AppSettings.shared
    
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
            
            FormFooterView(note: repair.note, photos: repair.sortedPhotosArray)
        }
        .navigationTitle("Repair Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button("Edit") {
                    showingEditRepair = true
                }
                .adaptiveTint()
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
    let repair = Repair(context: context)
    repair.name = "Tire Puncture Repaired"
    repair.odometer = 12345
    
    return RepairDetailView(repair: repair)
}
