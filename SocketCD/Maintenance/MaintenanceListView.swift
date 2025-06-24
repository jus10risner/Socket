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
            sortDescriptors: [NSSortDescriptor(keyPath: \Service.name_, ascending: true)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var showingAddService = false
    @State private var selectedService: Service? = nil
    @State private var isAnimating: Bool = false
    @State private var showingFirstServiceInfo = false
    
    var body: some View {
        maintenanceList
    }
    
    
    // MARK: - Views
    
    private var maintenanceList: some View {
        AppropriateNavigationType {
            List {
                servicesWithStatus(.overDue)
                
                servicesWithStatus(.due)
                
                servicesWithStatus(.notDue)
            
                if serviceTipDue == true {
                    firstServiceInfo
                }
            }
            .navigationTitle("Maintenance")
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
            .overlay {
                if showingFirstServiceInfo == true {
                    if let firstService = services.first {
                        MaintenanceOnboardingView(vehicle: vehicle, service: firstService, showingServiceRecordTip: $showingFirstServiceInfo)
                    }
                }
            }
            .overlay {
                if vehicle.sortedServicesArray.isEmpty {
                    MaintenanceStartView(showingAddService: $showingAddService)
                }
            }
            .onAppear { checkForNotificationPermission() }
            .onChange(of: Array(services)) { checkForNotificationPermission() }
            .onChange(of: vehicle.odometer) { vehicle.updateOdometerBasedNotifications() }
            .sheet(isPresented: $showingAddService, onDismiss: { determineIfFirstServiceInfoDue() }) {
                AddServiceView(vehicle: vehicle)
            }
            .sheet(item: $selectedService) { service in
                AddRecordView(vehicle: vehicle, service: service)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Spacer()
                        Text(vehicle.name)
                            .font(.headline)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.secondary)
                            .accessibilityLabel("Back to all vehicles")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddService = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityLabel("Add New Maintenance Service")
                    }
                    // iOS 16 workaround, where button could't be clicked again after sheet was dismissed - iOS 15 and 17 work fine without this
                    .id(UUID())
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    // Determines whether to show firstServiceInfo tip
    private var serviceTipDue: Bool {
        var serviceRecordCount = 0
        
        if allServices.count > 0 {
            for service in allServices {
                if service.serviceRecords?.count != 0 {
                    serviceRecordCount += 1
                }
            }
        }
        
        return serviceRecordCount == 0 ? true : false
    }
    
    // Shown when no services have been added for a given vehicle
    private var firstServiceInfo: some View {
        Section {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color(.socketPurple))
                    .accessibilityElement()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Now that you have a maintenance service set up, you can add a record each time this service is completed.")
                    
                    Text("Just swipe or tap on the service above, then tap \(Image(systemName: "plus.square.on.square.fill")) to add a new record.")
                        .accessibilityElement()
                        .accessibilityLabel("Just swipe or tap on a service above, then tap Add Service Record to add a new record.")
                }
                .padding(30)
                .font(.subheadline)
                .foregroundStyle(.white)
                .accessibilityElement(children: .combine)
            }
            .padding(.top, 30)
            .listRowSeparator(.hidden)
            .listRowBackground(Color(.systemGroupedBackground))
        }
    }
    
    
    // MARK: - Methods
    
    // Asks the user for permission to display notifications, when appropriate
    func checkForNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        if settings.notificationPermissionRequested == false && services.count > 0 {
            center.getNotificationSettings { permissions in
                if permissions.authorizationStatus == .notDetermined {
                    print("Requesting permission for notifications")
                    center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            print("Success!")
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                } else {
                    print("Notification permission has already been requested")
                }
            }
            
            settings.notificationPermissionRequested = true
        }
    }
    
    // Groups services with a given service status (not due, due, overdue) together, in a list
    func servicesWithStatus(_ serviceStatus: ServiceStatus) -> some View {
        ForEach(services, id: \.id) { service in
            if service.serviceStatus == serviceStatus {
                ServiceListRowView(selectedService: $selectedService, service: service, vehicle: vehicle)
            }
        }
    }
    
    // Determines whether to show MaintenanceOnboardingView
    func determineIfFirstServiceInfoDue() {
        if serviceTipDue == true && allServices.count == 1 {
            showingFirstServiceInfo = true
        }
    }
}

#Preview {
    MaintenanceListView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
}
