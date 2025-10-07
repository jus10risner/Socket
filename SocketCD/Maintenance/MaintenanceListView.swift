//
//  MaintenanceListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct MaintenanceListView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var vehicle: Vehicle
    
    // Used only to determine whether to show firstServiceInfo
    @FetchRequest(sortDescriptors: []) var allServices: FetchedResults<Service>
    
    // Used to populate the services list
    @FetchRequest var services: FetchedResults<Service>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var showingAddService = false
    @State private var showingLogService = false
//    @State private var isAnimating: Bool = false
    @State private var showingFirstServiceInfo = false
    
    var body: some View {
        ZStack {
            if vehicle.sortedServicesArray.isEmpty {
                EmptyMaintenanceView()
            } else {
                List {
                    ForEach(vehicle.sortedServicesArray) { service in
                        ServiceListRowView(service: service, vehicle: vehicle)
                    }
                    
//                    if serviceTipDue == true {
//                        firstServiceInfo
//                    }
                }
            }
        }
        .tint(settings.accentColor(for: .maintenanceTheme))
        .navigationTitle("Maintenance")
        .listRowSpacing(5)
        .overlay {
            if showingFirstServiceInfo == true {
                if let firstService = services.first {
                    MaintenanceOnboardingView(vehicle: vehicle, service: firstService, showingServiceRecordTip: $showingFirstServiceInfo)
                }
            }
        }
        .onAppear { requestNotificationPermission() }
        .onChange(of: Array(services)) { requestNotificationPermission() }
//        .onChange(of: vehicle.odometer) { vehicle.updateAllServiceNotifications() }
        .sheet(isPresented: $showingAddService) {
            AddEditServiceView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingLogService, content: {
            AddEditRecordView(vehicle: vehicle)
        })
        .toolbar {
            ToolbarItem {
                Button("Add Service", systemImage: "rectangle.badge.plus") {
                    showingAddService = true
                }
            }
            
            if #available(iOS 26, *) {
                ToolbarItem(placement: .principal) {
                    Text(vehicle.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    
    // MARK: - Views
    
//    // Determines whether to show firstServiceInfo tip
//    private var serviceTipDue: Bool {
//        var serviceRecordCount = 0
//        
//        if allServices.count > 0 {
//            for service in allServices {
//                if service.serviceRecords?.count != 0 {
//                    serviceRecordCount += 1
//                }
//            }
//        }
//        
//        return serviceRecordCount == 0 ? true : false
//    }
//    
//    // Shown when no services have been added for a given vehicle
//    private var firstServiceInfo: some View {
//        Section {
//            ZStack {
//                RoundedRectangle(cornerRadius: 10)
//                    .foregroundStyle(Color(.socketPurple))
//                    .accessibilityElement()
//                
//                VStack(alignment: .leading, spacing: 20) {
//                    Text("Now that you have a maintenance service set up, you can add a record each time this service is completed.")
//                    
//                    Text("Just swipe or tap on the service above, then tap \(Image(systemName: "plus.square.on.square.fill")) to add a new record.")
//                        .accessibilityElement()
//                        .accessibilityLabel("Just swipe or tap on a service above, then tap Add Service Record to add a new record.")
//                }
//                .padding(30)
//                .font(.subheadline)
//                .foregroundStyle(.white)
//                .accessibilityElement(children: .combine)
//            }
//            .padding(.top, 30)
//            .listRowSeparator(.hidden)
//            .listRowBackground(Color(.systemGroupedBackground))
//        }
//    }
    
    
    // MARK: - Methods
    
    // Asks the user for permission to display notifications, when appropriate
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined && services.count > 0 {
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
    
    // Groups services with a given service status (not due, due, overdue) together, in a list
//    func servicesWithStatus(_ serviceStatus: ServiceStatus) -> some View {
//        ForEach(services, id: \.id) { service in
//            if service.serviceStatus == serviceStatus {
//                ServiceListRowView(service: service, vehicle: vehicle)
//            }
//        }
//    }
    
    // Determines whether to show MaintenanceOnboardingView
//    func determineIfFirstServiceInfoDue() {
//        if serviceTipDue == true && allServices.count == 1 {
//            showingFirstServiceInfo = true
//        }
//    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return MaintenanceListView(vehicle: vehicle)
        .environmentObject(AppSettings())
}
