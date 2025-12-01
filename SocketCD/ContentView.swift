//
//  ContentView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @AppStorage("lastSelectedVehicleID") var lastSelectedVehicleID: String = ""
    
    @State private var onboardingSheet: ActiveOnboardingSheet?
    @State private var selectedVehicle: Vehicle?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VehicleListView(selectedVehicle: $selectedVehicle)
                .toolbar(removing: .sidebarToggle)
                .onChange(of: notificationBadgeNumber) {
                    // Sets the app icon's notification badge number
                    UNUserNotificationCenter.current().setBadgeCount(notificationBadgeNumber)
                }
        } detail: {
            if let vehicle = selectedVehicle {
                VehicleDashboardView(vehicle: vehicle, selectedVehicle: $selectedVehicle)
            } else {
                emptyDetailListView
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            checkForOnboardingViewsToShow()
            
            if let lastSelectedVehicle {
                selectedVehicle = lastSelectedVehicle
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                selectedVehicle = vehicles.first
            }
        }
        .onChange(of: selectedVehicle) { _ , value in
            lastSelectedVehicleID = value?.id?.uuidString ?? ""
        }
        .sheet(item: $onboardingSheet) { sheet in
            switch sheet {
            case .welcome:
                WelcomeView()
                    .onDisappear {
                        settings.welcomeViewShouldPresent = false
                        settings.savedAppVersion = AppInfo().version
                        print("Welcome dismissed! App version updated!")
                    }
            case .whatsNew:
                WhatsNewView()
                    .onDisappear {
                        settings.savedAppVersion = AppInfo().version
                        print("What's New dismissed! App version updated!")
                    }
            }
        }

    }
    
    
    // MARK: - Views
    
    private var emptyDetailListView: some View {
        Group {
            if vehicles.isEmpty {
                ContentUnavailableView("Add a Vehicle", systemImage: "arrow.left", description: Text("To get started, add a vehicle to your list."))
                    .symbolEffect(.pulse)
            } else {
                ContentUnavailableView("No Vehicle Selected", systemImage: "car.2.fill", description: Text("Choose a vehicle to see details here."))
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(" ")
                    .opacity(0)
            }
        }
        .navigationBarTitleDisplayMode(.large)
    }
    
    
    // MARK: - Computed Properties
    
    private var lastSelectedVehicle: Vehicle? {
        guard let uuid = UUID(uuidString: lastSelectedVehicleID) else { return nil }
        return vehicles.first { $0.id == uuid }
    }
    
    // Badge number for the app icon
    private var notificationBadgeNumber: Int {
        let allServices = vehicles.flatMap { $0.sortedServicesArray }
        let servicesDue = allServices.filter { $0.serviceStatus == .due || $0.serviceStatus == .overDue }
        
        return servicesDue.count
    }
    
    
    // MARK: - Methods
    
    private func checkForOnboardingViewsToShow() {
        let currentAppVersion = AppInfo().version
        let lastRunAppVersion = settings.savedAppVersion
        
        if settings.welcomeViewShouldPresent {
            onboardingSheet = .welcome
            print("Showing Welcome view")
        } else if lastRunAppVersion != currentAppVersion {
            onboardingSheet = .whatsNew
            print("Showing What's New view")
        }
    }
}

private enum ActiveOnboardingSheet: String, Identifiable {
    case welcome, whatsNew
    
    var id: String { rawValue }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
}
