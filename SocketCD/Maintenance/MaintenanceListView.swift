//
//  MaintenanceListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI
import TipKit

struct MaintenanceListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vehicle: Vehicle
    
    @FetchRequest var services: FetchedResults<Service>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var showingAddService = false
    @State private var showingLogService = false
    
    var body: some View {
        ZStack {
            if vehicle.sortedServicesArray.isEmpty {
                EmptyMaintenanceView()
            } else {
                List {
                    ForEach(vehicle.sortedServicesArray) { service in
                        ServiceListRowView(service: service, vehicle: vehicle)
                    }
                }
            }
        }
        .navigationTitle("Maintenance")
        .listRowSpacing(5)
        .sheet(isPresented: $showingAddService) {
            AddEditServiceView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingLogService, content: {
            AddEditRecordView(vehicle: vehicle)
        })
        .toolbar {
            ToolbarItem {
                Button {
                    showingAddService = true
                } label: {
                    Label("Set up New Service", image: "book.badge.plus")
                }
                .tint(Color.primary)
                .buttonStyle(.plain)
                .popoverTip(LogServiceTip())
                .tipImageSize(.init(width: 44, height: 44))
            }
            
            AdaptiveToolbarButton {
                Button {
                    showingLogService = true
                } label: {
                    Label("Log Service", systemImage: "plus")
                }
                .tint(Color.maintenanceTheme)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle) // defines button shape for iOS 17 & 18
                .disabled(services.isEmpty)
            }
            
            if #available(iOS 26, *) {
                ToolbarItem(placement: .principal) {
                    Text(vehicle.name)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return MaintenanceListView(vehicle: vehicle)
}
