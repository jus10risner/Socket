//
//  SelectedServicesListView.swift
//  SocketCD
//
//  Created by Justin Risner on 9/11/25.
//

import SwiftUI

struct SelectedServicesListView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var draftServiceLog: DraftServiceLog
    let vehicle: Vehicle
    
    var body: some View {
        List {
            Section("Select the services to log") {
                ForEach(vehicle.sortedServicesArray.sorted { $0.name < $1.name }) { service in
                    Button {
                        toggleSelection(for: service)
                    } label: {
                        LabeledContent(service.name) {
                            if let id = service.id, draftServiceLog.selectedServiceIDs.contains(id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.white, settings.accentColor(for: .maintenanceTheme))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        .imageScale(.large)
                        .foregroundStyle(Color.primary)
                    }
                }
            }
            .textCase(nil)
        }
    }
    
    private func toggleSelection(for service: Service) {
        guard let id = service.id else { return }
        
        if draftServiceLog.selectedServiceIDs.contains(id) {
            draftServiceLog.selectedServiceIDs.remove(id)
        } else {
            draftServiceLog.selectedServiceIDs.insert(id)
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    
    return SelectedServicesListView(draftServiceLog: DraftServiceLog(), vehicle: vehicle)
        .environmentObject(AppSettings())
}
