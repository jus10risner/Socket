//
//  AddEditFillupView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditFillupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftFillup = DraftFillup()
    let vehicle: Vehicle?
    let fillup: Fillup?
    
    init(vehicle: Vehicle? = nil, fillup: Fillup? = nil) {
        self.vehicle = vehicle
        self.fillup = fillup
        
        if let fillup {
            _draftFillup = StateObject(wrappedValue: DraftFillup(fillup: fillup))
        } else {
            _draftFillup = StateObject(wrappedValue: DraftFillup())
        }
    }
    
    var body: some View {
        NavigationStack {
            DraftFillupView(draftFillup: draftFillup, isEditView: true)
                .navigationTitle(fillup != nil ? "Edit Fill-up" : "New Fill-up")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            if let fillup {
                                fillup.updateAndSave(draftFillup: draftFillup)
                            } else if let vehicle {
                                vehicle.addNewFillup(draftFillup: draftFillup)
                            }
                            
                            dismiss()
                        }
                        .disabled(draftFillup.canBeSaved ? false : true)
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    
    AddEditFillupView(vehicle: Vehicle(context: context), fillup: Fillup(context: context))
}
