//
//  AddRepairView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct AddRepairView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftRepair = DraftRepair()
    let vehicle: Vehicle
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        
        _draftRepair = StateObject(wrappedValue: DraftRepair())
    }
    
    var body: some View {
        AppropriateNavigationType {
            DraftRepairView(draftRepair: draftRepair, isEditView: false)
                .navigationTitle("New Repair Record")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            vehicle.addNewRepair(draftRepair: draftRepair)
                            
                            dismiss()
                        }
                        .disabled(draftRepair.canBeSaved ? false : true)
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    AddRepairView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
}
