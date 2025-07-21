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
//    let vehicle: Vehicle
    var repair: Repair
    
    init(repair: Repair) {
        self.repair = repair
        
        _draftRepair = StateObject(wrappedValue: DraftRepair(repair: repair))
    }
    
    var body: some View {
        NavigationStack {
            DraftRepairView(draftRepair: draftRepair, isEditView: true)
                .navigationTitle("Edit Repair")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            repair.updateAndSave(draftRepair: draftRepair)
                            
                            dismiss()
                        }
                        .disabled(draftRepair.canBeSaved ? false : true)
                    }
                }
        }
    }
}

#Preview {
    EditRepairView(repair: Repair(context: DataController.preview.container.viewContext))
}
