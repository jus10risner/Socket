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
    @State var selectedService: Service? = nil
    @State var isAnimating: Bool = false
    
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
            
                if serviceHint == true {
                    firstServiceInfo
                }
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
            .overlay {
                if vehicle.sortedServicesArray.isEmpty {
                    MaintenanceStartView()
                }
            }
            .navigationTitle("Maintenance")
            .onAppear { restartAnimation() }
            .onChange(of: vehicle.sortedServicesArray) { _ in
                restartAnimation()
                
                guard settings.notificationPermissionRequested == true else {
                    requestNotificationPermission()
                    return
                }
            }
            .sheet(isPresented: $showingAddService) {
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
    private var serviceHint: Bool {
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
                
                Text("Add a record each time a maintenance service is performed, and Socket will help you remember when it's due next.")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(.top, 30)
            .listRowSeparator(.hidden)
            .listRowBackground(Color(.systemGroupedBackground))
        }
    }
    
    
    // MARK: - Methods
    
    // Restarts the arrow animation, when a service has been set up, but has no service records yet
    func restartAnimation() {
        isAnimating = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { isAnimating = true }
    }
    
    // Asks the user for permission to display notifications
    func requestNotificationPermission() {
        let settings = AppSettings()
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("Success!")
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        
        settings.notificationPermissionRequested = true
    }
    
    // Groups services with a given service status (not due, due, overdue) together, in a list
    func servicesWithStatus(_ serviceStatus: ServiceStatus) -> some View {
        ForEach(services, id: \.id) { service in
            if service.serviceStatus == serviceStatus {
                ServiceListRowView(selectedService: $selectedService, isAnimating: $isAnimating, service: service, vehicle: vehicle)
            }
        }
    }
}

#Preview {
    MaintenanceListView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
}
