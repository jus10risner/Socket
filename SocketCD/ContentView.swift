//
//  ContentView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettingsStore
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @AppStorage("lastSelectedVehicleID") var lastSelectedVehicleID: String = ""
    
    @State private var onboardingSheet: ActiveOnboardingSheet?
    @State private var selectedVehicle: Vehicle?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VehicleListView(selectedVehicle: $selectedVehicle)
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
        .sheet(item: $onboardingSheet, onDismiss: requestNotificationPermission) { sheet in
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
    
    // Splits the app version number into an array of Int (used in checkForOnboardingViewsToShow)
    private func parseVersion(_ version: String) -> [Int] {
        version.split(separator: ".").compactMap { Int($0) }
    }
    
    // Determines whether to display onboarding views and which to display
    private func checkForOnboardingViewsToShow() {
        let current = parseVersion(AppInfo().version)
        let previous = parseVersion(settings.savedAppVersion)
        
        // Are the app versions different?
        let isDifferent = current != previous
        
        // Do the versions have the same major and minor versions (e.g. 2.1)?
        let sameMajorMinor: Bool = {
            guard current.count >= 2, previous.count >= 2 else { return false }
            return current[0] == previous[0] && current[1] == previous[1]
        }()
        
        // Are the versions different, but with the same major and minor versions (e.g. 2.1.1 vs 2.1.2)?
        let isPatchUpdate = isDifferent && sameMajorMinor
        
        if settings.welcomeViewShouldPresent {
            onboardingSheet = .welcome
            print("Showing Welcome view")
        } else if isDifferent && !isPatchUpdate {
            onboardingSheet = .whatsNew
            print("Showing What's New view")
        } else {
            print("No onboarding sheet necessary")
        }
    }
    
    // Asks the user for permission to display notifications
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("Notification permission granted.")
                    } else if let error = error {
                        print("Notification permission error: \(error.localizedDescription)")
                    } else {
                        print("Notification permission not granted.")
                    }
                }
            }
        }
    }
}

private enum ActiveOnboardingSheet: String, Identifiable {
    case welcome, whatsNew
    
    var id: String { rawValue }
}

#Preview {
    ContentView()
        .environmentObject(AppSettingsStore())
}
