//
//  EditRepairView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct EditRepairView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftRepair = DraftRepair()
    let vehicle: Vehicle
    var repair: Repair
    
    init(vehicle: Vehicle, repair: Repair) {
        self.vehicle = vehicle
        self.repair = repair
        
        _draftRepair = StateObject(wrappedValue: DraftRepair(repair: repair))
    }
    
    var body: some View {
        AppropriateNavigationType {
            DraftRepairView(draftRepair: draftRepair, isEditView: true)
                .navigationTitle("Edit Repair")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            repair.updateAndSave(vehicle: vehicle, draftRepair: draftRepair)
                            
                            dismiss()
                        }
                        .disabled(draftRepair.canBeSaved ? false : true)
                    }
                }
        }
    }
}

#Preview {
    EditRepairView(vehicle: Vehicle(context: DataController.preview.container.viewContext), repair: Repair(context: DataController.preview.container.viewContext))
}
