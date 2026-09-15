//
//  MaintenanceCard.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/25.
//

import CoreData
import SwiftUI

struct MaintenanceCard: View {
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
        DashboardCard(
            title: "Maintenance",
            color: Color(.maintenanceTheme),
            quickActionTitle: "Add Service Log",
            accessibilityValue: accessibilityValue,
            accessibilityHint: String(localized: "Opens list of maintenance services"),
            disableButton: vehicle.sortedServicesArray.count < 1) {
                selectedSection = .maintenance
            } quickAction: {
                activeSheet = .logService
            } visual: {
                if let service = nextDueService {
                    ServiceIndicatorView(vehicle: vehicle, service: service)
                } else {
                    CardSymbolImage(symbolName: "book.and.wrench.fill", color: Color(.maintenanceTheme))
                }
            } detail: {
                if let service = nextDueService {
                    CardTextView(
                        headline: service.name,
                        subheadline: service.nextDueDescription(currentOdometer: vehicle.odometer)
                    )
                } else {
                    CardTextView(
                        headline: "Tap to get started",
                        subheadline: "Let’s set up your first service"
                    )
                }
            }
    }
    
    private var accessibilityValue: String {
        if let service = nextDueService {
            return String(localized: "\(service.name) \(service.nextDueDescription(currentOdometer: vehicle.odometer))")
        } else {
            return String(localized: "No services set up")
        }
    }
    
    // Determines which service is due next; updates the card content after a service is logged (and thus no longer due next)
    var nextDueService: Service? {
        return services.sorted { s1, s2 in
            switch (s1.estimatedDaysUntilDue(currentOdometer: vehicle.odometer),
                    s2.estimatedDaysUntilDue(currentOdometer: vehicle.odometer)) {
            case let (d1?, d2?):
                if d1 != d2 {
                    return d1 < d2
                } else if s1.name != s2.name {
                    return s1.name < s2.name
                } else {
                    return s1.id < s2.id
                }
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                if s1.name != s2.name {
                    return s1.name < s2.name
                } else {
                    return s1.id < s2.id
                }
            }
        }.first
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return MaintenanceCard(vehicle: vehicle, activeSheet: .constant(nil), selectedSection: .constant(nil))
}
