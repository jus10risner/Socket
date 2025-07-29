//
//  AddCustomInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct AddCustomInfoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftCustomInfo = DraftCustomInfo()
    @ObservedObject var vehicle: Vehicle
    
    @State private var showingDuplicateLabelError = false
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        
        _draftCustomInfo = StateObject(wrappedValue: DraftCustomInfo())
    }
    
    var body: some View {
        NavigationStack {
            DraftCustomInfoView(draftCustomInfo: draftCustomInfo, isEditView: false)
                .navigationTitle("New Vehicle Info")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            if vehicle.sortedCustomInfoArray.contains(where: { customInfo in customInfo.label == draftCustomInfo.label }) {
                                showingDuplicateLabelError = true
                            } else {
                                vehicle.addNewInfo(draftCustomInfo: draftCustomInfo)
                                
                                dismiss()
                            }
                        }
                        .disabled(draftCustomInfo.canBeSaved ? false : true)
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                }
                .alert("That label has already been used.", isPresented: $showingDuplicateLabelError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please choose a different label.")
                }
        }
    }
}

#Preview {
    AddCustomInfoView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
}
