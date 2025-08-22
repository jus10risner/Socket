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
    @FetchRequest var services: FetchedResults<Service>
    
    init(vehicle: Vehicle, selectedVehicle: Binding<Vehicle?>) {
        _draftVehicle = StateObject(wrappedValue: DraftVehicle(vehicle: vehicle))
        self.vehicle = vehicle
        self._selectedVehicle = selectedVehicle
        self._fillups = FetchRequest(
            entity: Fillup.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Fillup.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var selectedSection: AppSection?
    @State private var activeSheet: ActiveSheet?
    @State private var showingUpdateOdometerAlert = false
    @State private var showingDeleteAlert = false
    
    @State private var exportURL: URL?
    @State private var shareItem: ShareItem?
    @State private var showingPageSizeSelector = false
    
    let columns = [GridItem(.adaptive(minimum: 300), spacing: 5)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    maintenanceDashboardCard
                    
                    fillupsDashboardCard
                    
                    HStack(spacing: 5) {
                        repairsDashboardCard
                        
                        odometerDashboardCard
                    }
                }
                
                customInfo
                    .padding(.top, 30)
            }
            .padding(.horizontal)
            .scrollContentBackground(.hidden)
            .background(GradientBackground())
            .navigationTitle(vehicle.name)
            .navigationDestination(item: $selectedSection) { section in
                switch section {
                case .maintenance:
                    destinationView(for: .maintenance, vehicle: vehicle)
                case .repairs:
                    destinationView(for: .repairs, vehicle: vehicle)
                case .fillups:
                    destinationView(for: .fillups, vehicle: vehicle)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addService:
                    AddEditServiceView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .maintenanceTheme))
                case .addRepair:
                    AddEditRepairView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .repairsTheme))
                case .addFillup:
                    AddEditFillupView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .fillupsTheme))
                case .addCustomInfo:
                    AddEditCustomInfoView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .appTheme))
                case .editVehicle:
                    EditVehicleView(vehicle: vehicle)
                        .tint(settings.accentColor(for: .appTheme))
                }
            }
            .sheet(item: $shareItem) { item in
                ActivityView(activityItems: [item.url])
            }
            .alert("Update Odometer", isPresented: $showingUpdateOdometerAlert, actions: {
                TextField("New Odometer Reading", value: $draftVehicle.odometer, format: .number.decimalSeparator(strategy: .automatic))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    vehicle.updateAndSave(draftVehicle: draftVehicle)
                }
            })
            .toolbar {
                vehicleToolbar
            }
        }
    }
    
    private var odometerDashboardCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 3) {
                    Image(systemName: "car.fill")
                        .frame(width: 20)
                    
                    Text("Odometer")
                }
                .foregroundStyle(settings.accentColor(for: .appTheme))
                .font(.subheadline.bold())
                .accessibilityLabel("Odometer")
                
                Spacer()
            }
            
            HStack {
                Text("\(vehicle.odometer.formatted())")
                    .font(.title3.bold())
                
                Spacer()
                
                Button("Update Odometer", systemImage: "pencil.circle.fill") { showingUpdateOdometerAlert = true }
                    .symbolRenderingMode(.hierarchical)
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .tint(settings.accentColor(for: .appTheme))
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
        .contentShape(Rectangle())
    }
    
    private var maintenanceDashboardCard: some View {
        DashboardCard(title: "Maintenance", systemImage: "book.and.wrench.fill", accentColor: settings.accentColor(for: .maintenanceTheme), buttonLabel: "Add Service Log") {
            activeSheet = .addService
        } content: {
            if let service = nextDueService {
                HStack {
                    ServiceIndicatorView(vehicle: vehicle, service: service)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(service.name)
                            .font(.title3.bold())

                        Text(service.nextDueDescription(currentOdometer: vehicle.odometer))
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .onTapGesture {
            selectedSection = .maintenance
        }
    }
    
    private var fillupsDashboardCard: some View {
        DashboardCard(title: "Fill-ups", systemImage: "fuelpump.fill", accentColor: settings.accentColor(for: .fillupsTheme), buttonLabel: "Add Fill-up") {
            activeSheet = .addFillup
        } content: {
            if let fillup = vehicle.sortedFillupsArray.first {
                HStack {
                    if fillups.count > 1 {
                        TrendArrowView(fillups: fillups)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Latest Fill-up")
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                        
                        Text("\(fillup.fuelEconomy(settings: settings), format: .number.precision(.fractionLength(1))) \(settings.fuelEconomyUnit.rawValue)")
                            .font(.title3.bold())
                    }
                }
            }
        }
        .onTapGesture {
            selectedSection = .fillups
        }
    }
    
    private var repairsDashboardCard: some View {
        DashboardCard(title: "Repairs", systemImage: "wrench.fill", accentColor: settings.accentColor(for: .repairsTheme), buttonLabel: "Add Repair") {
            activeSheet = .addRepair
        } content: {
            EmptyView()
        }
        .onTapGesture {
            selectedSection = .repairs
        }
    }
    
    private var customInfo: some View {
        VStack(alignment: .leading) {
            Text("Custom Info")
                .font(.headline)
                .padding(.leading)
            
            LazyVGrid(columns: columns, spacing: 5) {
                if !vehicle.sortedCustomInfoArray.isEmpty {
                    ForEach(vehicle.sortedCustomInfoArray, id: \.id) { customInfo in
                        NavigationLink {
                            CustomInfoDetailView(customInfo: customInfo)
                        } label: {
                            HStack {
                                Text(customInfo.label)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
                    }
                    
                    Button {
                        activeSheet = .addCustomInfo
                    } label: {
                        Label("Add Info", systemImage: "plus")
                            .foregroundStyle(settings.accentColor(for: .appTheme))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle.adaptive
                                    .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 0.5, dash: [5, 3]))
                            }
                    }
                } else {
                    VStack(spacing: 5) {
                        Button {
                            activeSheet = .addCustomInfo
                        } label: {
                            Label("Add Info", systemImage: "plus")
                                .foregroundStyle(settings.accentColor(for: .appTheme))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle.adaptive
                                        .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 0.5, dash: [5, 3]))
                                }
                        }
                        
                        Text("Add things like your vehicle's VIN or photos of important documents here, for easy reference.")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
                    }
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var vehicleToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Menu("Vehicle Options", systemImage: "ellipsis") {
                Button("Edit Vehicle", systemImage: "pencil") { activeSheet = .editVehicle }
                
                exportMenu
                
                Divider()
                
                Button("Delete Vehicle", systemImage: "trash", role: .destructive) { showingDeleteAlert = true }
            }
            .confirmationDialog("Which paper size do you prefer?", isPresented: $showingPageSizeSelector, titleVisibility: .visible) {
                Button("A4") { exportPDF(pageSize: .a4) }
                
                Button("US Letter") { exportPDF(pageSize: .usLetter) }
                
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog("Permanently delete \(vehicle.name) and all of its records? \nThis action cannot be undone.", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    DataController.shared.delete(vehicle)
                    selectedVehicle = nil
                }
                
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private func exportPDF(pageSize: PDFPaperSize) {
        Task {
            if let exportURL = PDFExporter.export(vehicle: vehicle, paperSize: pageSize) {
                shareItem = ShareItem(url: exportURL)
            }
        }
    }
    
    private func csvExportButton(title: String, _ action: @escaping () async -> URL?) -> some View {
        Button(title) {
            Task {
                if let exportURL = await action() {
                    shareItem = ShareItem(url: exportURL)
                }
            }
        }
    }
    
    // Menu, including buttons for exporting/sharing vehicle records.
    private var exportMenu: some View {
        Menu("Export Records", systemImage: "square.and.arrow.up") {
            Section("Printable Document (PDF)") {
                Button("Maintenance & Repairs") { showingPageSizeSelector = true }
            }
            
            Section("Spreadsheet (CSV)") {
                csvExportButton(title: "All Records") { CSVExporter.exportAllRecords(for: vehicle) }
                csvExportButton(title: "Fill-ups") { CSVExporter.exportFillups(for: vehicle) }
                csvExportButton(title: "Maintenance & Repairs") { CSVExporter.exportServicesAndRepairs(for: vehicle) }
            }
        }
        .accessibilityHint("Save or share records for this vehicle")
    }
    
    @ViewBuilder
    private func destinationView(for section: AppSection, vehicle: Vehicle) -> some View {
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
    
    // Returns the next service due (or most overdue)
    private var nextDueService: Service? {
        services.sorted {
            switch ($0.estimatedDaysUntilDue(currentOdometer: vehicle.odometer),
                    $1.estimatedDaysUntilDue(currentOdometer: vehicle.odometer)) {
            case let (d1?, d2?):
                return d1 < d2
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                return $0.name < $1.name
            }
        }
        .first
    }
}

// Creates a gradient background, with backgroundExtensionEffect applied on iOS 26+ (for iPad use)
struct GradientBackground: View {
    var body: some View {
        let gradient = LinearGradient(
            colors: [
                Color.indigo.opacity(0.5),
                Color(.systemGroupedBackground),
                Color(.systemGroupedBackground),
                Color(.systemGroupedBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        Group {
            if #available(iOS 26, *) {
                gradient.backgroundExtensionEffect()
            } else {
                gradient
            }
        }
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}

// Allows ActivityView to work with the .sheet(item:) modifier (requires a URL with Identifiable conformance)
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

enum ActiveSheet: String, Identifiable {
    case addService, addRepair, addFillup, addCustomInfo, editVehicle
    
    var id: String { rawValue }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleDashboardView(vehicle: vehicle, selectedVehicle: .constant(vehicle))
        .environmentObject(AppSettings())
}
