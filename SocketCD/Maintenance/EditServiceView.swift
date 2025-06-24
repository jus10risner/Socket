//
//  EditServiceView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct EditServiceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftService = DraftService()
    @ObservedObject var vehicle: Vehicle
    var service: Service
    
    init(vehicle: Vehicle, service: Service) {
        self.vehicle = vehicle
        self.service = service
        
        _draftService = StateObject(wrappedValue: DraftService(service: service))
    }
    
    @State private var selectedInterval: ServiceIntervalTypes = .distance
    
    var body: some View {
        NavigationStack {
            DraftServiceView(draftService: draftService, selectedInterval: $selectedInterval, isEditView: true)
                .navigationTitle("Edit Service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            service.updateAndSave(vehicle: vehicle, draftService: draftService, selectedInterval: selectedInterval)
                            
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
        }
    }
}

#Preview {
    EditServiceView(vehicle: Vehicle(context: DataController.preview.container.viewContext), service: Service(context: DataController.preview.container.viewContext))
}
