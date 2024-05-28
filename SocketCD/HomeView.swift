//
//  HomeView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var dataController: DataController
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @State private var showingAddVehicle = false
    @State private var showingSettings = false
    @State private var selectedVehicle: Vehicle?
    
    @State private var showingOnboardingTip = false
    
    var body: some View {
        homeView
    }
    
    
    // MARK: - Views
    
    private var homeView: some View {
        AppropriateNavigationType {
            VehicleListView(selectedVehicle: $selectedVehicle)
                .overlay {
                    if vehicles.isEmpty {
                        EmptyVehicleListView()
                    }
                }
                .modifier(RemoveBackgroundColor()) // Required for iOS 16.0 to display the customBackground color
                .background(Color(.customBackground))
                .navigationTitle("Vehicles")
                .onAppear { checkForViewsToBeShownOnLaunch() }
                .onChange(of: notificationBadgeNumber) { _ in
                    // Sets the app icon's notification badge number
                    UIApplication.shared.applicationIconBadgeNumber = notificationBadgeNumber
                }
                .onChange(of: [settings.daysBeforeMaintenance, settings.distanceBeforeMaintenance]) { _ in
                    setUpNotifications(cancelPending: true)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .background {
                        setUpNotifications(cancelPending: false)
                    }
                }
                .onChange(of: selectedVehicle) { _ in
                    if settings.onboardingTipsAlreadyPresented == false {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            settings.onboardingTipsAlreadyPresented = true
                        }
                    }
                }
                .sheet(item: $selectedVehicle) { vehicle in
                    // Needs to be here, rather than on VehicleListView, for ShareLink to work properly
                    VehicleTabView(vehicle: vehicle)
                }
                .sheet(isPresented: $showingSettings) { AppSettingsView() }
                .sheet(isPresented: $showingAddVehicle, onDismiss: { checkOnboardingTipsStatus() }) { AddVehicleView() }
                .sheet(isPresented: $settings.welcomeViewPresented) { WelcomeView() }
                .overlay {
                    if showingOnboardingTip {
                        OnboardingTips(showingOnboardingTip: $showingOnboardingTip, vehicle: vehicles[0])
                    }
                }
                .toolbar {
                    #if DEBUG
                    ToolbarItemGroup(placement: .topBarLeading) {
                        dataController.cloudContainerAvailable ? Image(systemName: "checkmark.icloud") : Image(systemName: "xmark.icloud")
                        
                        Button {
                            settings.welcomeViewPresented = true
                            settings.onboardingTipsAlreadyPresented = false
                        } label: {
                            Image(systemName: "sparkles")
                        }
                    }
                    #endif
                    
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Group {
                            Button {
                                showingAddVehicle = true
                            } label: {
                                Image(systemName: "plus")
                                    .accessibilityLabel("Add a Vehicle")
                            }
                            
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .accessibilityLabel("Settings")
                            }
                        }
                    }
                }
                // Fires only if there is a problem loading or saving Core Data persistent stores
                .alert("No Data Found", isPresented: $dataController.isShowingDataError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("\nThere was a problem loading data. \n\nIf your device is low on storage space, try deleting some unused apps, then restart Socket. \n\nPlease reinstall Socket, if the issue persists.")
                }

        }
        .conditionalTint(.primary)
    }
    
    
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
            } else if vehicles.count > 1 {
                settings.onboardingTipsAlreadyPresented = true
            }
        }
    }
    
    // Schedules notifications, if appropriate, when the app's scenePhase is set to .background. Cancels all pending notifications, if cancelPending is true.
    func setUpNotifications(cancelPending: Bool) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { permissions in
            guard permissions.authorizationStatus == .authorized else {
                print("Push notifications have not been authorized")
                return
            }
            
            for vehicle in vehicles {
                for service in vehicle.sortedServicesArray {
                    if cancelPending == true {
                        // Cancels all pending notifications on the device
                        service.cancelPendingNotifications()
                    }
                    
                    service.updateNotifications(vehicle: vehicle)
                }
            }
        }
    }
}

#Preview {
    HomeView(dataController: DataController())
        .environmentObject(AppSettings())
}
