//
//  AddEditRepairView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct AddEditRepairView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftRepair = DraftRepair()
    let vehicle: Vehicle
    var repair: Repair?
    
    init(vehicle: Vehicle, repair: Repair? = nil) {
        self.vehicle = vehicle
        self.repair = repair
        
        _draftRepair = StateObject(wrappedValue: DraftRepair(repair: repair))
    }
    
    var body: some View {
        NavigationStack {
            DraftRepairView(draftRepair: draftRepair, isEditView: true)
                .navigationTitle(repair != nil ? "Edit Repair" : "New Repair")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            if let repair {
                                repair.updateAndSave(draftRepair: draftRepair)
                            } else {
                                vehicle.addNewRepair(draftRepair: draftRepair)
                            }
                            
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
    AddEditRepairView(vehicle: Vehicle(context: DataController.preview.container.viewContext), repair: Repair(context: DataController.preview.container.viewContext))
}
