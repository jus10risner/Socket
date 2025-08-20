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
            AddEditRecordView(service: service)
        }
        .swipeActions(edge: .leading) {
            Button {
                selectedService = service
            } label: {
                Label("Add Service Record", systemImage: "plus.square.on.square")
            }
            .tint(settings.accentColor(for: .maintenanceTheme))
        }
    }
    
    
    // MARK: - Views
    
    // Vertical capsule shape that changes color and shape, to indicate service status
//    private var serviceStatusIndicator: some View {
//        Group {
//            if service.serviceStatus == .due || service.serviceStatus == .overDue {
//                VStack(spacing: 5) {
//                    Capsule()
//                        .frame(width: 5, height: 30)
//                    
//                    Circle()
//                        .frame(width: 5)
//                }
//            } else {
//                Capsule()
//                    .frame(width: 5, height: 40)
//            }
//        }
//        .foregroundStyle(service.indicatorColor)
//    }
    
    // Service name and relevant info
    private var serviceInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(service.name)
                .font(.headline)
            
            if service.sortedServiceRecordsArray.isEmpty {
                Text("Swipe or tap to add a service record")
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
