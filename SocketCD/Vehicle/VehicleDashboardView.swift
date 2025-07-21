//
//  VehicleDashboardView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/10/25.
//

import SwiftUI

struct VehicleDashboardView: View {
    @EnvironmentObject var settings: AppSettings
    let vehicle: Vehicle
    
    @FetchRequest var fillups: FetchedResults<Fillup>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._fillups = FetchRequest(
            entity: Fillup.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Fillup.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var selectedSection: AppSection?
    @State private var showingAddService = false
    @State private var showingAddRepair = false
    @State private var showingAddFillup = false
    @State private var showingFuelEconomyInfo = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    maintenanceDashboardCard(vehicle: vehicle)
                    
                    HStack{
                        odometerDashboardCard(vehicle: vehicle)
                        
                        fuelEconomyDashboardCard(vehicle: vehicle)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                Section("Records") {
                    quickActionButtons
                        .listRowInsets(EdgeInsets())
                    
                    ForEach(AppSection.allCases, id: \.self) { section in
                        NavigationLink {
                            destinationView(for: section, vehicle: vehicle)
                        } label: {
                            sectionLabel(section: section)
                        }
                    }
                }
                .headerProminence(.increased)
            }
            .listRowSpacing(5)
            .listStyle(.insetGrouped)
            //            }
            //            .background(Color(.systemGroupedBackground))
            .scrollContentBackground(.hidden)
            .background {
                LinearGradient(colors: [Color.indigo.opacity(0.5), Color(.systemGroupedBackground), Color(.systemGroupedBackground), Color(.systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
            .navigationTitle(vehicle.name)
            .sheet(isPresented: $showingAddService) {
                AddServiceView(vehicle: vehicle)
//                    .tint(settings.accentColor(for: .maintenanceTheme))
                    .tint(settings.accentColor(for: .maintenanceTheme))
            }
            .sheet(isPresented: $showingAddRepair) {
                AddRepairView(vehicle: vehicle)
                    .tint(settings.accentColor(for: .repairsTheme))
            }
            .sheet(isPresented: $showingAddFillup) {
                AddFillupView(vehicle: vehicle, quickFill: false)
                    .tint(settings.accentColor(for: .fillupsTheme))
            }
//            .sheet(isPresented: $showingFuelEconomyInfo) { FuelEconomyInfoView() }
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        // Vehicle Settings
//                    } label: {
//                        Label("Settings", systemImage: "ellipsis.circle")
//                    }
//                }
//            }
        }
//        }
//        .tint(.primary)
    }
    
    func odometerDashboardCard(vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Odometer", systemImage: "road.lanes")
                .labelStyle(.titleOnly)
                .font(.headline)
                .foregroundStyle(settings.accentColor(for: .appTheme))
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(vehicle.odometer)")
                    .font(.title3.bold())
                
                Text(settings.distanceUnit.abbreviated)
                    .foregroundStyle(Color.secondary)
                
                Spacer()
                
                Image(systemName: "pencil")
                    .font(.title2.bold())
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(settings.accentColor(for: .appTheme))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
    }
    
    func fuelEconomyDashboardCard(vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Latest Fill-up", systemImage: "fuelpump.fill")
                .labelStyle(.titleOnly)
                .font(.headline)
                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
            
            if let fillup = vehicle.sortedFillupsArray.dropFirst().first {
                HStack {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(fillup.fuelEconomy, format: .number.precision(.fractionLength(1)))
                            .font(.title3.bold())
                        
                        Text(settings.fuelEconomyUnit.rawValue)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Spacer()
                    
                    TrendArrowView(fillups: fillups)
//                        .scaleEffect(0.75)
                }
            } else {
                Text("No Fill-ups")
                    .font(.title3.bold())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
    }
    
    func maintenanceDashboardCard(vehicle: Vehicle) -> some View {
        return VStack(alignment: .leading, spacing: 10) {
            Label("Next Service Due", systemImage: "book.and.wrench.fill")
                .labelStyle(.titleOnly)
                .font(.headline)
                .foregroundStyle(settings.accentColor(for: .maintenanceTheme))
            
            if let service = nextDueService(from: vehicle.sortedServicesArray, currentOdometer: vehicle.odometer) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(service.name)
                            .font(.title3.bold())
                        
                        Text(service.nextDueDescription(context: ServiceContext(service: service, currentOdometer: vehicle.odometer)))
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Spacer()
                    
                    ServiceIndicatorView(vehicle: vehicle, service: service)
                }
            } else {
                Text("No Services Scheduled")
                    .font(.title3.bold())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
    }
    
    private func sectionLabel(section: AppSection) -> some View {
        Label {
            Text(section.rawValue.capitalized)
                .foregroundStyle(Color.primary)
        } icon: {
            Image(systemName: section.symbol)
        }
        .foregroundStyle(settings.accentColor(for: section.theme))
        .listRowSeparator(.hidden)
    }
    
    private var quickActionButtons: some View {
        HStack(spacing: 5) {
            Button {
                showingAddService = true
            } label: {
                //                                    Label("Log Maintenance", systemImage: "plus.circle.fill")
                Label("Log Maintenance", image: "book.and.wrench.fill.badge.plus")
                    .foregroundStyle(settings.accentColor(for: .maintenanceTheme))
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            
            Button {
                showingAddRepair = true
            } label: {
                //                                    Label("Add Repair", systemImage: "plus.circle.fill")
                Label("Add Repair", image: "wrench.adjustable.fill.badge.plus")
                    .foregroundStyle(settings.accentColor(for: .repairsTheme))
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            
            Button {
                showingAddFillup = true
            } label: {
                //                                    Label("Fill-up", systemImage: "plus")
                Label("Add Fill-up", image: "fuelpump.fill.badge.plus")
                    .foregroundStyle(settings.accentColor(for: .fillupsTheme))
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
    }
    
    // Returns the next service due (or the most overdue service)
    func nextDueService(from services: [Service], currentOdometer: Int) -> Service? {
        let prioritized = services.compactMap { service -> (service: Service, priority: Int)? in
            let context = ServiceContext(service: service, currentOdometer: currentOdometer)
            guard let priority = priority(context: context) else { return nil }
            
            return (service: service, priority: priority)
        }

        return prioritized.min { $0.priority < $1.priority }?.service
    }
    
    // Calculates the miles or days left until service is due
    func priority(context: ServiceContext) -> Int? {
        switch (context.daysUntilDue, context.milesUntilDue) {
        case let (d?, m?):
            return min(d, m)
        case let (d?, nil):
            return d
        case let (nil, m?):
            return m
        default:
            return nil
        }
    }
    
    @ViewBuilder
    func destinationView(for section: AppSection, vehicle: Vehicle) -> some View {
        switch section {
        case .maintenance:
            MaintenanceListView(vehicle: vehicle)
                .tint(settings.accentColor(for: section.theme))
        case .repairs:
            RepairsListView(vehicle: vehicle)
                .tint(settings.accentColor(for: section.theme))
        case .fillups:
            FillupsDashboardView(vehicle: vehicle)
                .tint(settings.accentColor(for: section.theme))
        case .vehicle:
            VehicleInfoView(vehicle: vehicle)
                .tint(section.color)
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleDashboardView(vehicle: vehicle)
        .environmentObject(AppSettings())
}
