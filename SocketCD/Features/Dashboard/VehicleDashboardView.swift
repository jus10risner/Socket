//
//  VehicleDashboardView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/10/25.
//

import SwiftUI
import TipKit

struct VehicleDashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject var draftVehicle = DraftVehicle()
    @ObservedObject var vehicle: Vehicle
    @Binding var selectedVehicle: Vehicle? // Used primarily to dismiss this view if the vehicle is deleted
    let settings = AppSettingsStore.shared
    
    init(vehicle: Vehicle, selectedVehicle: Binding<Vehicle?>) {
        _draftVehicle = StateObject(wrappedValue: DraftVehicle(vehicle: vehicle))
        self.vehicle = vehicle
        self._selectedVehicle = selectedVehicle
    }
    
    @State private var selectedSection: AppSection?
    @State private var activeSheet: ActiveSheet?
    @State private var showingUpdateOdometerAlert = false
    @State private var newOdometerValue: Int? = nil
    
    @State private var exportURL: URL?
    @State private var shareItem: ShareItem?
    @State private var showingPageSizeSelector = false
    
    let columns = [GridItem(.adaptive(minimum: 300), spacing: 5)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                TipView(DashboardTip())
                    .tipBackground(Color(.tertiarySystemBackground))
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(vehicle.name)
                            .font(.largeTitle.bold())
                            .lineLimit(2)
                        
                        HStack(spacing: 10) {
                            Text("\(vehicle.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                                .font(.title3)
                                .accessibilityLabel("Odometer: \(vehicle.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                            
                            Button("Update Odometer", systemImage: "pencil") {
                                showingUpdateOdometerAlert = true
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                        }
                    }
                    
                    Spacer()
                }
                
                LazyVGrid(columns: columns, spacing: 5) {
                    MaintenanceCard(vehicle: vehicle, activeSheet: $activeSheet, selectedSection: $selectedSection)
                    
                    FillupsCard(vehicle: vehicle, activesheet: $activeSheet, selectedSection: $selectedSection)
                    
                    RepairsCard(vehicle: vehicle, activeSheet: $activeSheet, selectedSection: $selectedSection)
                    
                    CustomInfoCard(vehicle: vehicle, activeSheet: $activeSheet, selectedSection: $selectedSection)
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(item: $selectedSection) { section in
                destinationView(for: section, vehicle: vehicle)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .logService:
                    AddEditRecordView(service: vehicle.sortedServicesArray.first, vehicle: vehicle)
                case .addRepair:
                    AddEditRepairView(vehicle: vehicle)
                case .addFillup:
                    AddEditFillupView(vehicle: vehicle)
                case .addCustomInfo:
                    AddEditCustomInfoView(vehicle: vehicle)
                case .editVehicle:
                    AddEditVehicleView(vehicle: vehicle, onDelete: { selectedVehicle = nil })
                case .showTimeline:
                    TimelineView(vehicle: vehicle)
                }
            }
            .sheet(item: $shareItem) { item in
                ActivityView(activityItems: [item.url])
            }
            .alert("Update Odometer", isPresented: $showingUpdateOdometerAlert, actions: {
                TextField("\(draftVehicle.odometer ?? 0)", value: $newOdometerValue, format: .number.decimalSeparator(strategy: .automatic))
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) { newOdometerValue = nil }
                Button("Save") {
                    if let newOdometer = newOdometerValue {
                        draftVehicle.odometer = newOdometer
                        vehicle.updateAndSave(draftVehicle: draftVehicle)
                    }
                }
                .disabled(newOdometerValue == nil)
            }, message: {
                Text("Enter the current odometer value.")
            })
            .toolbar {
                vehicleToolbar
            }
        }
    }
    
    @ToolbarContentBuilder
    private var vehicleToolbar: some ToolbarContent {
        ToolbarItem {
            Menu("Vehicle Options", systemImage: "ellipsis") {
                if !vehicle.groupedServiceAndRepairTimeline.isEmpty {
                    Button {
                        activeSheet = .showTimeline
                    } label: {
                        Label("Full Timeline", systemImage: "list.bullet")
                        Text("Maintenance and Repairs")
                    }
                }
                
                exportMenu
                
                Divider()
                
                Button("Edit Vehicle", systemImage: "pencil") { activeSheet = .editVehicle }
            }
            .adaptiveTint()
            .confirmationDialog("Which paper size do you prefer?", isPresented: $showingPageSizeSelector, titleVisibility: .visible) {
                Button("A4") { exportPDF(pageSize: .a4) }
                
                Button("US Letter") { exportPDF(pageSize: .usLetter) }
                
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
                Button("Maintenance and Repairs") { showingPageSizeSelector = true }
            }
            
            Section("Spreadsheet (CSV)") {
                csvExportButton(title: "All Vehicle Records") { CSVExporter.exportAllRecords(for: vehicle) }
                csvExportButton(title: "Fill-ups") { CSVExporter.exportFillups(for: vehicle) }
                csvExportButton(title: "Maintenance and Repairs") { CSVExporter.exportMaintenanceAndRepairs(for: vehicle) }
            }
        }
        .accessibilityHint("Save or share records for this vehicle")
    }
    
    @ViewBuilder
    private func destinationView(for section: AppSection, vehicle: Vehicle) -> some View {
        switch section {
        case .maintenance:
            MaintenanceListView(vehicle: vehicle)
        case .repairs:
            RepairsListView(vehicle: vehicle)
        case .fillups:
            FillupsDashboardView(vehicle: vehicle)
        case .customInfo:
            CustomInfoListView(vehicle: vehicle)
        }
    }
}

// Allows ActivityView to work with the .sheet(item:) modifier (requires a URL with Identifiable conformance)
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

// Sheet options for VehicleDashboardView
enum ActiveSheet: String, Identifiable {
    case logService, addRepair, addFillup, addCustomInfo, editVehicle, showTimeline
    
    var id: String { rawValue }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleDashboardView(vehicle: vehicle, selectedVehicle: .constant(vehicle))
}
