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
    
    // Used to determine whether to show QuickFillTip
    @FetchRequest(sortDescriptors: []) var fillups: FetchedResults<Fillup>
    
    @State private var showingAddVehicle = false
    @State private var showingSettings = false
    @State private var selectedVehicle: Vehicle?
    
    @State var showingQuickFillTip = false
    
    var body: some View {
        homeView
    }
    
    
    // MARK: - Views
    
    private var homeView: some View {
        AppropriateNavigationType {
            VehicleListView(selectedVehicle: $selectedVehicle)
                .overlay {
                    if vehicles.isEmpty {
                        emptyState
                    }
                }
                .background(Color(.customBackground))
                .navigationTitle("Vehicles")
                .onAppear { checkForViewsToBeShownOnLaunch() }
                .onChange(of: notificationBadgeNumber) { _ in UIApplication.shared.applicationIconBadgeNumber = notificationBadgeNumber }
                .onChange(of: [settings.daysBeforeMaintenance, settings.distanceBeforeMaintenance]) { _ in
                    setUpNotifications(reschedule: true)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .background {
                        setUpNotifications(reschedule: false)
                    }
                }
                .sheet(item: $selectedVehicle) { vehicle in
                    // Needs to be here, rather than on VehicleListView, for ShareLink to work properly
                    VehicleTabView(vehicle: vehicle)
                }
                .sheet(isPresented: $showingSettings) { AppSettingsView() }
                .sheet(isPresented: $showingAddVehicle) { AddVehicleView() }
                .sheet(isPresented: $settings.welcomeViewPresented) { WelcomeView() }
                .overlay {
                    if showingQuickFillTip {
                        QuickFillTip(showingQuickFillTip: $showingQuickFillTip, vehicle: vehicles[0])
                    }
                }
                .toolbar {
                    #if DEBUG
                    ToolbarItemGroup(placement: .topBarLeading) {
                        dataController.cloudContainerAvailable ? Image(systemName: "checkmark.icloud") : Image(systemName: "xmark.icloud")
                        
                        Button {
                            settings.welcomeViewPresented = true
                            settings.quickFillTipPresented = false
                        } label: {
                            Image(systemName: "sparkles")
                            //                                .foregroundStyle(Color.clear)
                        }
                    }
                    #endif
                    
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        // Not ideal, but the Add Vehicle toolbar button would stop working after its sheet was dismissed, until I added the text below to the toolbar; now it functions as expected.
    //                    Text(showingAddVehicle ? " " : "").hidden()
                        
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
                        .disabled(showingQuickFillTip)
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
    
    // What the user sees when there are no vehicles in the model
    private var emptyState: some View {
        ZStack {
            Color(.customBackground)
            
            VStack(spacing: 10) {
                Image(systemName: "car.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color(.socketPurple))
                    .accessibilityHidden(true)
                
                VStack {
                    Text("Add a Vehicle")
                        .font(.title2.bold())
                    
                    Text("Tap the plus button to get started.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityElement()
                .accessibilityLabel("Tap the Add a Vehicle button to get started")
            }
        }
        .ignoresSafeArea()
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
        checkQuickFillTipStatus()
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
    
    // Checks to see whether to show QuickFillTip
    func checkQuickFillTipStatus() {
        if settings.welcomeViewPresented == false && settings.quickFillTipPresented == false {
            print("welcome view shown, but not quick fill")
            if fillups.count > 0 {
                showingQuickFillTip = true
                settings.quickFillTipPresented = true
            }
        }
    }
    
    // Schedules notifications, if appropriate, when the app's scenePhase is set to .background
    func setUpNotifications(reschedule: Bool) {
        UNUserNotificationCenter.current().getNotificationSettings { permissions in
            if permissions.authorizationStatus == .authorized {
                for vehicle in vehicles {
                    for service in vehicle.sortedServicesArray {
                        if reschedule == true {
                            service.cancelPendingNotifications()
                        }
                        
                        // Sets up notifications for any service that is due, but does not yet have a notification scheduled; this ensures that each device syncing with iCloud gets its own local notifications, when appropriate
                        if service.notificationScheduled == false {
                                if let dateDue = service.dateDue {
                                    if let alertDate = Calendar.current.date(byAdding: .day, value: Int(-settings.daysBeforeMaintenance), to: dateDue) {
                                    if dateDue > Date.now && alertDate > Date.now {
                                        service.scheduleNotificationOnDate(dateDue, for: vehicle)
                                    }
                                }
                            }
                            
                            if let odometerDue = service.odometerDue {
                                let distanceToNextService = odometerDue - vehicle.odometer
                                
                                if distanceToNextService <= settings.distanceBeforeMaintenance && distanceToNextService >= 0 {
                                    service.scheduleNotificationForTomorrow(for: vehicle)
                                }
                            }
                        }
                    }
                }
            } else {
               print("Push notifications have not been authorized")
           }
        }
    }
}

#Preview {
    HomeView(dataController: DataController())
        .environmentObject(AppSettings())
}
