//
//  VehicleDashboardView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/10/25.
//

import SwiftUI

struct VehicleDashboardView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject var draftVehicle = DraftVehicle()
    @ObservedObject var vehicle: Vehicle
    @Binding var selectedVehicle: Vehicle? // Used primarily to dismiss this view if the vehicle is deleted
    
    @FetchRequest var fillups: FetchedResults<Fillup>
    
    init(vehicle: Vehicle, selectedVehicle: Binding<Vehicle?>) {
        _draftVehicle = StateObject(wrappedValue: DraftVehicle(vehicle: vehicle))
        self.vehicle = vehicle
        self._selectedVehicle = selectedVehicle
        self._fillups = FetchRequest(
            entity: Fillup.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Fillup.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var selectedSection: AppSection?
    @State private var activeSheet: ActiveSheet?
    @State private var showingUpdateOdometerAlert = false
    @State private var showingDeleteAlert = false
    
    @State private var odometerValue = ""
    
    let columns: [GridItem] = {
        [GridItem(.adaptive(minimum: 300), spacing: 5)]
    }()
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LazyVGrid(columns: columns, spacing: 5) {
                        maintenanceDashboardCard
                        
                        fuelEconomyDashboardCard
                        
                        quickAddDashboardCard
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                
                Section("Records") {
                    ForEach(AppSection.allCases, id: \.self) { section in
                        NavigationLink {
                            destinationView(for: section, vehicle: vehicle)
                        } label: {
                            sectionLabel(section: section)
                        }
                    }
                }
                .headerProminence(.increased)
                
                vehicleInfo
            }
//            .listRowSpacing(5)
//            .listStyle(.insetGrouped)
            //            }
            //            .background(Color(.systemGroupedBackground))
            .scrollContentBackground(.hidden)
            .background {
                LinearGradient(colors: [Color.indigo.opacity(0.5), Color(.systemGroupedBackground), Color(.systemGroupedBackground), Color(.systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
            .navigationTitle(vehicle.name)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addService:
                    AddEditServiceView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .maintenanceTheme))
                case .addRepair:
                    AddEditRepairView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .repairsTheme))
                case .addFillup:
//                    AddFillupView(vehicle: vehicle, quickFill: false)
                    AddEditFillupView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .fillupsTheme))
                case .addCustomInfo:
                    AddCustomInfoView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .appTheme))
                case .editVehicle:
                    EditVehicleView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .appTheme))
                
                }
            }
            .alert("Update Odometer", isPresented: $showingUpdateOdometerAlert, actions: {
                TextField("New Odometer Reading", value: $draftVehicle.odometer, format: .number.decimalSeparator(strategy: .automatic))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) { }
                Button("OK") {
                    vehicle.updateAndSave(draftVehicle: draftVehicle)
                }
            }, message: {
                Text("Enter the current odometer reading for \(vehicle.name).")
            })
            .confirmationDialog("Permanently delete \(vehicle.name) and all of its records? \nThis action cannot be undone.", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    DataController.shared.delete(vehicle)
                    selectedVehicle = nil
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            activeSheet = .editVehicle
                        } label: {
                            Label("Edit Vehicle", systemImage: "pencil")
                        }
                        
                        exportMenu
                        
                        Section {
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Vehicle", systemImage: "trash")
                            }
                        }
                    } label: {
                        Label("Vehicle Options", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    var vehicleInfo: some View {
        Section {
            if vehicle.sortedCustomInfoArray.isEmpty {
                VStack(spacing: 20) {
                    Text("Add things like your vehicle's VIN or license plate number here, for easy reference.")
                        .foregroundStyle(Color.secondary)
                    
                    //                            HStack(spacing: 3) {
                    //                                Text("Tap")
                    //
                    //                                addInfoButton
                    //
                    //                                Text("to add vehicle info")
                    //                            }
                    //                            .frame(maxWidth: .infinity)
                }
                .font(.subheadline)
                .padding(.horizontal, 5)
                .padding(.vertical, 20)
            } else {
                ForEach(vehicle.sortedCustomInfoArray, id: \.id) { customInfo in
                    NavigationLink {
                        CustomInfoDetailView(customInfo: customInfo)
                    } label: {
                        Text(customInfo.label)
                    }
                }
            }
        } header: {
            HStack {
                Text("Custom Info")
                
                Spacer()
                
                Button {
                    activeSheet = .addCustomInfo
                } label: {
                    Label("Add Custom Info", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, settings.accentColor(for: .appTheme))
                }
            }
        }
        .headerProminence(.increased)
    }
    
    var maintenanceDashboardCard: some View {
        DashboardCardView(title: "Next Service Due", systemImage: "book.and.wrench.fill", accentColor: settings.accentColor(for: .maintenanceTheme)) {
            Group {
                if let service = vehicle.nextServiceDue() {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(service.name)
                                .font(.title3.bold())
                            
                            Text(service.nextDueDescription(context: ServiceContext(service: service, currentOdometer: vehicle.odometer)))
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        Spacer()
                        
                        ServiceIndicatorView(vehicle: vehicle, service: service)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Nothing to see here...")
                            .font(.title3)
                        
                        Text("Log a maintenance service to see when it's due next.")
                            .font(.footnote)
                            
                    }
                    .foregroundStyle(Color.secondary)
                }
            }
        }
    }
    
    var fuelEconomyDashboardCard: some View {
        DashboardCardView(title: "Latest Fill-up", systemImage: "fuelpump.fill", accentColor: settings.accentColor(for: .fillupsTheme)) {
            Group {
                if let fillup = vehicle.sortedFillupsArray.first {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text("\(fillup.fuelEconomy(settings: settings), format: .number.precision(.fractionLength(1))) \(settings.fuelEconomyUnit.rawValue)")
                                    .font(.title3.bold())
                            }
                            
                            Text(fillup.date.formatted(date: .numeric, time: .omitted))
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        Spacer()
                        
                        if fillups.count > 1 {
                            TrendArrowView(fillups: fillups)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Not Enough Info")
                            .font(.title3)
                        
                        Text("Add some fill-ups to see your latest fuel economy.")
                            .font(.footnote)
                            
                    }
                    .foregroundStyle(Color.secondary)
                }
            }
        }
    }
    
    var quickAddDashboardCard: some View {
        DashboardCardView(title: "Quick Actions", systemImage: "road.lanes", accentColor: settings.accentColor(for: .appTheme)) {
            quickActionButtons
        }
    }
    
    // Menu, including buttons for exporting/sharing vehicle records. iOS 15 doesn't display section headers in menus, so there's some conditional logic for showing the appropriate header style
    private var exportMenu: some View {
        Menu {
            Section {
                Button {
//                    showingPageSizeSelector = true
                } label: {
                    Label("PDF", systemImage: "doc")
                }
                
                Button {
//                    createMaintenanceRepairsCSV()
//                    showingActivityView = true
                } label: {
                    Label("CSV", systemImage: "tablecells")
                }
            } header: {
                Text("Maintenance & Repairs")
            }
            .accessibilityHint("Export maintenance and repair records for this vehicle")
            
            Section {
                Button {
//                    createFillupsCSV()
//                    showingActivityView = true
                } label: {
                    Label("CSV", systemImage: "tablecells")
                }
            } header: {
                Text("Fill-ups")
            }
            .accessibilityHint("Export fill-up records for this vehicle")
        } label: {
            Label("Export Records", systemImage: "square.and.arrow.up")
        }
    }
    
    private func sectionLabel(section: AppSection) -> some View {
//        Label {
            Text(section.rawValue.capitalized)
//                .foregroundStyle(Color.primary)
//        } icon: {
//            Image(systemName: section.symbol)
//        }
//        .foregroundStyle(settings.accentColor(for: section.theme))
    }
    
    private var quickActionButtons: some View {
        let columns: [GridItem] = {[GridItem(.adaptive(minimum: 150), spacing: 10)]}()
        
        return LazyVGrid(columns: columns, spacing: 10) {
            QuickAddButton(accent: settings.accentColor(for: .maintenanceTheme)) {
                activeSheet = .addService
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(settings.accentColor(for: .maintenanceTheme))
                    
                    Text("Maintenance")
                }
                .accessibilityLabel("Add Maintenance Service")
            }

            QuickAddButton(accent: settings.accentColor(for: .repairsTheme)) {
                activeSheet = .addRepair
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(settings.accentColor(for: .repairsTheme))
                    
                    Text("Repair")
                }
                .accessibilityLabel("Add Repair")
            }

            QuickAddButton(accent: settings.accentColor(for: .fillupsTheme)) {
                activeSheet = .addFillup
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                    
                    Text("Fill-up")
                }
                .accessibilityLabel("Add Fill-up")
            }
            
            QuickAddButton(accent: settings.accentColor(for: .appTheme)) {
                showingUpdateOdometerAlert = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "pencil")
                        .font(.headline)
                        .foregroundStyle(settings.accentColor(for: .appTheme))
                    
                    Text("Odometer")
                }
                .accessibilityLabel("Update Odometer")
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
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
        }
    }
}

struct DashboardCardView<Content: View>: View {
    let title: String
    let systemImage: String
    let accentColor: Color
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleOnly)
                .font(.headline)
                .foregroundStyle(accentColor)

            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct QuickAddButton<Label: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let accent: Color
    let action: () -> Void
    let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
//                .foregroundStyle(accent)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .contentShape(Capsule())
        }
        .background {
            Capsule()
                .fill(Color(.tertiarySystemGroupedBackground))
//                .stroke(accent, lineWidth: 1)
        }
    }
}

enum ActiveSheet: Identifiable {
    case addService, addRepair, addFillup, addCustomInfo, editVehicle
    
    var id: String {
        switch self {
        case .addService: return "addService"
        case .addRepair: return "addRepair"
        case .addFillup: return "addFillup"
        case .addCustomInfo : return "addCustomInfo"
        case .editVehicle: return "editVehicle"
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleDashboardView(vehicle: vehicle, selectedVehicle: .constant(vehicle))
        .environmentObject(AppSettings())
}
