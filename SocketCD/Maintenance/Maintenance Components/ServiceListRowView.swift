//
//  ServiceListRowView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/20/24.
//

import SwiftUI

struct ServiceListRowView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var service: Service
    @ObservedObject var vehicle: Vehicle
    
    @State private var selectedService: Service?
    
    var body: some View {
        NavigationLink {
            ServiceDetailView(service: service, vehicle: vehicle)
                .tint(settings.accentColor(for: .maintenanceTheme))
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
            .tint(settings.accentColor(for: .maintenanceTheme))
        }
    }
    
    
    // MARK: - Views
    
    // Service name and relevant info
    private var serviceInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(service.name)
                .font(.headline)
            
            if service.sortedServiceRecordsArray.isEmpty {
                Text("Swipe or tap to add a service log")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            } else {
                Text(service.nextDueDescription(currentOdometer: vehicle.odometer))
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    
    let service = Service(context: context)
    service.name = "Oil Change"
    
    return ServiceListRowView(service: service, vehicle: vehicle)
        .environmentObject(AppSettings())
}
