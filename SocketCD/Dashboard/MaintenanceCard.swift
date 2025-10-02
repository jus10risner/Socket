//
//  MaintenanceCard.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/25.
//

import SwiftUI

struct MaintenanceCard: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var vehicle: Vehicle
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var selectedSection: AppSection?
    
    @FetchRequest var services: FetchedResults<Service>
    
    init(vehicle: Vehicle, activeSheet: Binding<ActiveSheet?>, selectedSection: Binding<AppSection?>) {
        self.vehicle = vehicle
        self._activeSheet = activeSheet
        self._selectedSection = selectedSection
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    var body: some View {
        DashboardCard(title: "Maintenance", systemImage: "book.and.wrench.fill", accentColor: settings.accentColor(for: .maintenanceTheme), buttonLabel: "Add Service Log", buttonSymbol: "plus", showingAddButton: vehicle.sortedServicesArray.count > 0) {
            activeSheet = .logService
        } content: {
            if let service = vehicle.sortedServicesArray.first {
                HStack {
                    ServiceIndicatorView(vehicle: vehicle, service: service)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(service.name)
                            .font(.title3.bold())

                        Text(service.nextDueDescription(currentOdometer: vehicle.odometer))
                            .font(.footnote.bold())
                            .foregroundStyle(Color.secondary)
                    }
                }
            } else {
                Text("Tap to get started")
                    .font(.title3.bold())
            }
        }
        .onTapGesture {
            selectedSection = .maintenance
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return MaintenanceCard(vehicle: vehicle, activeSheet: .constant(nil), selectedSection: .constant(nil))
        .environmentObject(AppSettings())
}
