//
//  ContentView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var dataController: DataController
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @State private var selectedVehicle: Vehicle?
    
    @State private var showingOnboardingTip = false
    @State private var showingOnboardingText = false
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VehicleListView(selectedVehicle: $selectedVehicle, showingOnboardingText: $showingOnboardingText)
                .toolbar(removing: .sidebarToggle)
//                .onChange(of: notificationBadgeNumber) {
//                    // Sets the app icon's notification badge number
//                    UNUserNotificationCenter.current().setBadgeCount(notificationBadgeNumber)
//                }
        } detail: {
            if let selectedVehicle {
                VehicleDashboardView(vehicle: selectedVehicle)
            } else {
                Text("Please select a vehicle")
            }
        }
        .tint(.primary)
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            if let firstVehicle = vehicles.first {
                selectedVehicle = firstVehicle
            }
        }
    }
    
    
    // MARK: - Views
    
//    private var homeView: some View {
//        NavigationStack {
//            VehicleListView(selectedVehicle: $selectedVehicle, showingOnboardingText: $showingOnboardingText)
//                .overlay {
//                    if vehicles.isEmpty {
//                        EmptyVehicleListView()
//                    }
//                }
//                .scrollContentBackground(.hidden)
//                .background(Color(.customBackground))
//                .navigationTitle("Vehicles")
//                .onAppear { checkForViewsToBeShownOnLaunch() }
//                .onChange(of: notificationBadgeNumber) {
//                    // Sets the app icon's notification badge number
////                    UIApplication.shared.applicationIconBadgeNumber = notificationBadgeNumber
//                    UNUserNotificationCenter.current().setBadgeCount(notificationBadgeNumber)
//                }
//                .onChange(of: [settings.daysBeforeMaintenance, settings.distanceBeforeMaintenance]) {
//                    setUpNotifications(cancelPending: true)
//                }
//                .onChange(of: selectedVehicle) {
//                    if settings.onboardingTipsAlreadyPresented == false {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
//                            showingOnboardingText = false
//                            settings.onboardingTipsAlreadyPresented = true
//                        }
//                    }
//                    
//                    DispatchQueue.main.async {
//                        // Ensures that all devices syncing via iCloud have the same local notifications
//                        setUpNotifications(cancelPending: false)
//                    }
//                }
//                .sheet(item: $selectedVehicle) { vehicle in
//                    // Needs to be here, rather than on VehicleListView, for ShareLink to work properly
//                    VehicleTabView(vehicle: vehicle)
//                }
//                .sheet(isPresented: $showingSettings) { AppSettingsView() }
//                .sheet(isPresented: $showingAddVehicle, onDismiss: { checkOnboardingTipsStatus() }) { AddVehicleView() }
//                .sheet(isPresented: $settings.welcomeViewPresented) { WelcomeView() }
//                .overlay {
//                    if showingOnboardingTip {
//                        OnboardingTips(showingOnboardingTip: $showingOnboardingTip, vehicle: vehicles[0])
//                    }
//                }
//                .toolbar {
//                    #if DEBUG
//                    ToolbarItemGroup(placement: .topBarLeading) {
//                        dataController.cloudContainerAvailable ? Image(systemName: "checkmark.icloud") : Image(systemName: "xmark.icloud")
//                        
//                        Button {
//                            settings.welcomeViewPresented = true
//                            settings.onboardingTipsAlreadyPresented = false
//                        } label: {
//                            Image(systemName: "sparkles")
//                        }
//                    }
//                    #endif
//                    
//                    ToolbarItemGroup(placement: .topBarTrailing) {
//                        Group {
//                            Button {
//                                showingAddVehicle = true
//                            } label: {
//                                Image(systemName: "plus")
//                                    .accessibilityLabel("Add a Vehicle")
//                            }
//                            
//                            Button {
//                                showingSettings = true
//                            } label: {
//                                Image(systemName: "gearshape")
//                                    .accessibilityLabel("Settings")
//                            }
//                        }
//                    }
//                }
//                // Fires only if there is a problem loading or saving Core Data persistent stores
//                .alert("No Data Found", isPresented: $dataController.isShowingDataError) {
//                    Button("OK", role: .cancel) { }
//                } message: {
//                    Text("\nThere was a problem loading data. \n\nIf your device is low on storage space, try deleting some unused apps, then restart Socket. \n\nPlease reinstall Socket, if the issue persists.")
//                }
//
//        }
//        .tint(.primary)
//    }
    
    
    // MARK: - Computed Properties
    
    // Badge number for the app icon
    private var notificationBadgeNumber: Int {
        var count = 0

        for vehicle in vehicles {
            for service in vehicle.sortedServicesArray {
                if service.serviceStatus == .due || service.serviceStatus == .overDue {
                    count += 1
                }
            }
        }
        
        return count
    }
    
    
    // MARK: - Methods
    
    // Check to see if any informational views (welcome/update/tips) should be shown
    func checkForViewsToBeShownOnLaunch() {
        // Removes delivered notifications from Notification Center
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        checkForVersionUpdate()
    }
    
    // Checks app's version number, to determine whether to show What's New View (in the future)
    func checkForVersionUpdate() {
        let version = AppInfo().version
        let savedVersion = settings.savedAppVersion
        
        if savedVersion == version {
            print("Version up to date! \(savedVersion)")
        } else {
            settings.savedAppVersion = version
            print("Version updated to \(version)")
            
            if settings.welcomeViewPresented == false {
                // Show What's New view
            }
        }
    }
    
    // Checks to see whether to show OnboardingTips
    func checkOnboardingTipsStatus() {
        if settings.welcomeViewPresented == false && settings.onboardingTipsAlreadyPresented == false {
            if vehicles.count == 1 {
                showingOnboardingTip = true
                showingOnboardingText = true
            } else if vehicles.count > 1 {
                settings.onboardingTipsAlreadyPresented = true
            }
        }
    }
    
    // Schedules local notifications, if appropriate
    func setUpNotifications(cancelPending: Bool) {
        for vehicle in vehicles {
            if cancelPending == true {
                for service in vehicle.sortedServicesArray {
                    service.cancelPendingNotifications()
                }
            }
            
            vehicle.updateAllNotifications()
        }
    }
}

#Preview {
    ContentView(dataController: DataController())
        .environmentObject(AppSettings())
}
