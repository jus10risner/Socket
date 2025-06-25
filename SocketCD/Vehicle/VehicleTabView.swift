//
//  VehicleTabView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct VehicleTabView: View {
    @EnvironmentObject var settings: AppSettings
    let vehicle: Vehicle
    
    @FetchRequest var services: FetchedResults<Service>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var selectedTab: SelectedTab = .maintenance
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MaintenanceListView(vehicle: vehicle)
                .tabItem {
                    Label("Maintenance", systemImage: "book.and.wrench")
                }
                .tint(Color.selectedColor(for: .maintenanceTheme))
                .tag(SelectedTab.maintenance)
                .badge(tabBadgeNumber)

            RepairsListView(vehicle: vehicle)
                .tabItem {
                    Label("Repairs", systemImage: "wrench")
                }
                .tint(Color.selectedColor(for: .repairsTheme))
                .tag(SelectedTab.repairs)

            FillupsDashboardView(vehicle: vehicle)
                .tabItem {
                    Label("Fill-ups", systemImage: "fuelpump")
                }
                .tint(Color.selectedColor(for: .fillupsTheme))
                .tag(SelectedTab.fillups)

            VehicleInfoView(vehicle: vehicle)
                .tabItem {
                    Label("Vehicle", systemImage: "car")
                }
                .tint(.selectedColor(for: .appTheme))
                .tag(SelectedTab.vehicleInfo)
        }
        .tint(selectedTab.color())
//        .transition(.move(edge: .bottom))
    }
    
    
    // MARK: - Computed Properties
    
    // Calculates number to place inside of Maintenance tab badge (if any)
    var tabBadgeNumber: Int {
        var count = 0

        for service in services {
            if service.serviceStatus == .due || service.serviceStatus == .overDue {
                count += 1
            }
        }
        return count
    }
}
