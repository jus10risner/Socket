//
//  AddEditServiceView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditServiceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftService = DraftService()
    @ObservedObject var vehicle: Vehicle
    var service: Service?
    
    init(vehicle: Vehicle, service: Service? = nil) {
        self.vehicle = vehicle
        self.service = service
        
        _draftService = StateObject(wrappedValue: DraftService(service: service))
    }
    
    @State private var showingDuplicateNameError = false
    @State private var selectedInterval: ServiceIntervalTypes = .distance
    
    var body: some View {
        NavigationStack {
            DraftServiceView(draftService: draftService, selectedInterval: $selectedInterval, isEditView: true)
                .navigationTitle(service != nil ? "Edit Service" : "New Maintenance Service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            if let service {
                                service.updateAndSave(vehicle: vehicle, draftService: draftService, selectedInterval: selectedInterval)
                            } else {
                                if vehicle.sortedServicesArray.contains(where: { service in service.name == draftService.name }) {
                                    showingDuplicateNameError = true
                                } else {
                                    vehicle.addNewService(draftService: draftService, selectedInterval: selectedInterval)
                                }
                            }
                            
                            dismiss()
                        }
                        .disabled(draftService.canBeSaved ? false : true)
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                }
                .onAppear {
                    if draftService.distanceInterval != 0 && draftService.timeInterval == 0 {
                        selectedInterval = .distance
                    } else if draftService.timeInterval != 0 && draftService.distanceInterval == 0 {
                        selectedInterval = .time
                    } else {
                        selectedInterval = .both
                    }
                }
                .alert("This vehicle already has a service with that name", isPresented: $showingDuplicateNameError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please choose a different name.")
                }
        }
    }
}

#Preview {
    AddEditServiceView(vehicle: Vehicle(context: DataController.preview.container.viewContext), service: Service(context: DataController.preview.container.viewContext))
}
