//
//  ServiceListRowView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/20/24.
//

import SwiftUI

struct ServiceListRowView: View {
    @Binding var selectedService: Service?
//    @Binding var isAnimating: Bool
    @ObservedObject var service: Service
    let vehicle: Vehicle
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
            
            NavigationLink {
                ServiceDetailView(service: service, vehicle: vehicle)
            } label: {
                HStack {
                    serviceStatusIndicator
                    
                    serviceInfo
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color(.systemGroupedBackground))
        .listRowInsets(EdgeInsets(top: 2.5, leading: 20, bottom: 2.5, trailing: 20))
//        .padding(.vertical, 5)
        .swipeActions(edge: .leading) {
            Button {
                selectedService = service
            } label: {
                Label("Add Service Record", systemImage: "plus.square.on.square")
            }
            .tint(Color.selectedColor(for: .maintenanceTheme))
        }
    }
    
    
    // MARK: - Views
    
    // Vertical capsule shape that changes color and shape, to indicate service status
    private var serviceStatusIndicator: some View {
        Group {
            if service.serviceStatus == .due || service.serviceStatus == .overDue {
                VStack(spacing: 5) {
                    Capsule()
                        .frame(width: 5, height: 30)
                    
                    Circle()
                        .frame(width: 5)
                }
            } else {
                Capsule()
                    .frame(width: 5, height: 40)
            }
        }
        .foregroundStyle(service.indicatorColor)
    }
    
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
                Text(service.nextServiceDueDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    ServiceListRowView(selectedService: .constant(Service(context: DataController.preview.container.viewContext)), service: Service(context: DataController.preview.container.viewContext), vehicle: Vehicle(context: DataController.preview.container.viewContext))
}
