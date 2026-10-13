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
                .buttonBorderShape(.circle)
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

private struct ServiceListRowView: View {
    @ObservedObject var service: Service
    @ObservedObject var vehicle: Vehicle
    
    @State private var selectedService: Service?
    
    var body: some View {
        NavigationLink {
            ServiceDetailView(service: service, vehicle: vehicle)
        } label: {
            Label {
                serviceInfo
            } icon: {
                ServiceIndicatorView(vehicle: vehicle, service: service)
            }
            .labelStyle(CenteredLabelStyle())
        }
        .listRowSeparator(.hidden)
        .sheet(item: $selectedService) { service in
            AddEditRecordView(service: service, vehicle: vehicle)
        }
        .swipeActions(edge: .leading) {
            Button("Add Service Log", systemImage: "plus") {
                selectedService = service
            }
            .tint(Color(.maintenanceTheme))
        }
    }
    
    // Service name and relevant info
    private var serviceInfo: some View {
        VStack(alignment: .leading) {
            Text(service.name)
                .font(.headline)
            
            if service.sortedServiceRecordsArray.isEmpty {
                Text("Tap the plus button to add a service log")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            } else {
                Text(service.nextDueDescription(currentOdometer: vehicle.odometer))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
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
