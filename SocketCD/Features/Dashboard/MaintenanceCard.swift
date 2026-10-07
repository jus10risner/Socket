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
    @Binding var servicesForNewLog: [Service]
    
    @FetchRequest var services: FetchedResults<Service>
    
    init(
        vehicle: Vehicle,
        activeSheet: Binding<ActiveSheet?>,
        selectedSection: Binding<AppSection?>,
        servicesForNewLog: Binding<[Service]>
    ) {
        self.vehicle = vehicle
        self._activeSheet = activeSheet
        self._selectedSection = selectedSection
        self._servicesForNewLog = servicesForNewLog
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
            quickActionTitle: quickActionTitle,
            accessibilityValue: accessibilityValue,
            accessibilityHint: accessibilityHint,
            disableButton: vehicle.sortedServicesArray.count < 1
        ) {
            selectedSection = .maintenance
        } quickAction: {
            servicesForNewLog = servicesRepresentedOnCard
            activeSheet = .logService
        } visual: {
            if let service = nextDueService {
                DashboardServiceIndicator(vehicle: vehicle, service: service)
            } else {
                CardSymbolView(symbolName: "book.and.wrench.fill")
            }
        } detail: {
            if let service = nextDueService {
                CardTextView(
                    headline: cardHeadline(for: service),
                    subheadline: cardSubheadline(for: service)
                )
            } else {
                CardTextView(
                    headline: "Know when service is due",
                    subheadline: "Tap here to set up your first service"
                )
            }
        }
    }
    
    private var accessibilityValue: String {
        if let service = nextDueService {
            return String(localized: "\(cardHeadline(for: service)) \(cardSubheadline(for: service))")
        } else {
            return String(localized: "No services set up")
        }
    }

    private func cardHeadline(for service: Service) -> String {
        guard servicesRepresentedOnCard.count > 1 else { return service.name }

        if servicesNeedingAttention.isEmpty {
            return String(localized: "\(servicesRepresentedOnCard.count) Services")
        } else {
            return String(localized: "\(servicesRepresentedOnCard.count) Services Need Attention")
        }
    }

    private func cardSubheadline(for service: Service) -> String {
        guard servicesNeedingAttention.count > 1 else {
            return service.nextDueDescription(currentOdometer: vehicle.odometer)
        }

        let overdueCount = servicesNeedingAttention.count { $0.serviceStatus == .overDue }
        let dueCount = servicesNeedingAttention.count { $0.serviceStatus == .due }

        if overdueCount > 0 && dueCount > 0 {
            return String(localized: "\(overdueCount) overdue, \(dueCount) due")
        } else if overdueCount > 0 {
            return String(localized: "\(overdueCount) overdue")
        } else {
            return String(localized: "\(dueCount) due")
        }
    }

    private var quickActionTitle: String {
        if servicesRepresentedOnCard.count > 1 {
            return String(localized: "Log \(servicesRepresentedOnCard.count) services")
        } else if let service = servicesRepresentedOnCard.first {
            return String(localized: "Log \(service.name)")
        } else {
            return String(localized: "Log Service")
        }
    }

    private var servicesRepresentedOnCard: [Service] {
        servicesNeedingAttention.isEmpty ? nextDueServices : servicesNeedingAttention
    }

    private var servicesNeedingAttention: [Service] {
        services.filter { $0.serviceStatus == .due || $0.serviceStatus == .overDue }
    }

    private var nextDueServices: [Service] {
        guard let nextDueService else { return [] }

        return services.filter {
            $0.odometerDue == nextDueService.odometerDue
                && datesMatch($0.dateDue, nextDueService.dateDue)
        }
    }

    private func datesMatch(_ firstDate: Date?, _ secondDate: Date?) -> Bool {
        switch (firstDate, secondDate) {
        case let (firstDate?, secondDate?):
            return Calendar.current.isDate(firstDate, inSameDayAs: secondDate)
        case (nil, nil):
            return true
        default:
            return false
        }
    }

    private var accessibilityHint: String {
        if services.isEmpty {
            return String(localized: "Opens Maintenance to set up your first service")
        } else {
            return String(localized: "Opens list of maintenance services")
        }
    }
    
    // Determines which service is due next; updates the card content after a service is logged (and thus no longer due next)
    var nextDueService: Service? {
        return services.sorted { s1, s2 in
            let statusPriority1 = statusPriority(for: s1.serviceStatus)
            let statusPriority2 = statusPriority(for: s2.serviceStatus)

            if statusPriority1 != statusPriority2 {
                return statusPriority1 < statusPriority2
            }

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

    private func statusPriority(for status: ServiceStatus) -> Int {
        switch status {
        case .overDue:
            return 0
        case .due:
            return 1
        case .notDue:
            return 2
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return MaintenanceCard(
        vehicle: vehicle,
        activeSheet: .constant(nil),
        selectedSection: .constant(nil),
        servicesForNewLog: .constant([])
    )
}
