//
//  AddServiceView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddServiceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftService = DraftService()
    @ObservedObject var vehicle: Vehicle
    
    @State private var showingDuplicateNameError = false
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        
        _draftService = StateObject(wrappedValue: DraftService())
    }
    
    @State private var selectedInterval: ServiceIntervalTypes = .distance
    
    var body: some View {
        AppropriateNavigationType {
            DraftServiceView(draftService: draftService, selectedInterval: $selectedInterval, isEditView: false)
                .navigationTitle("New Maintenance Service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            if vehicle.sortedServicesArray.contains(where: { service in service.name == draftService.name }) {
                                showingDuplicateNameError = true
                            } else {
                                vehicle.addNewService(draftService: draftService, selectedInterval: selectedInterval)
                                
                                dismiss()
                            }
                        }
                        .disabled(draftService.canBeSaved ? false : true)
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                }
                .alert("This vehicle already has a service with that name", isPresented: $showingDuplicateNameError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("\nPlease choose a different name.")
                }
        }
    }
}

#Preview {
    AddServiceView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
}
