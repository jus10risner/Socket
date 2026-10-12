//
//  MaintenanceListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import CoreData
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
        List {
            ForEach(vehicle.sortedServicesArray) { service in
                ServiceListRowView(service: service, vehicle: vehicle)
            }
        }
        .vehicleNavigationTitle("Maintenance", vehicleName: vehicle.name)
        .listRowSpacing(5)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .overlay {
            if vehicle.sortedServicesArray.isEmpty {
                EmptyMaintenanceListView {
                    showingAddService = true
                }
            }
        }
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
                    Label("Set up New Service", image: "checklist.unchecked.square.badge.plus")
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
        }
    }
}


// MARK: - Subviews

private struct EmptyMaintenanceListView: View {
    let action: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("No Services", systemImage: "book.and.wrench")
        } description: {
            Text("Start by setting up a routine maintenance service, then add a log each time it is completed.")
        } actions: {
            Button {
                action()
            } label: {
                Label("Set Up a Service", image: "checklist.unchecked.square.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(.maintenanceTheme))
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
