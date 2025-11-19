//
//  VehicleDashboardView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/10/25.
//

import SwiftUI
import TipKit

struct VehicleDashboardView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject var draftVehicle = DraftVehicle()
    @ObservedObject var vehicle: Vehicle
    @Binding var selectedVehicle: Vehicle? // Used primarily to dismiss this view if the vehicle is deleted
    
    init(vehicle: Vehicle, selectedVehicle: Binding<Vehicle?>) {
        _draftVehicle = StateObject(wrappedValue: DraftVehicle(vehicle: vehicle))
        self.vehicle = vehicle
        self._selectedVehicle = selectedVehicle
    }
    
    @State private var selectedSection: AppSection?
    @State private var activeSheet: ActiveSheet?
    @State private var showingUpdateOdometerAlert = false
    @State private var newOdometerValue: Int? = nil
    @State private var showingDeleteAlert = false
    
    @State private var exportURL: URL?
    @State private var shareItem: ShareItem?
    @State private var showingPageSizeSelector = false
    
    let columns = [GridItem(.adaptive(minimum: 300), spacing: 5)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    HStack(spacing: 5) {
                        odometerDashboardCard
                        
                        RepairsCard(vehicle: vehicle, activeSheet: $activeSheet, selectedSection: $selectedSection)
                    }
                    
                    MaintenanceCard(vehicle: vehicle, activeSheet: $activeSheet, selectedSection: $selectedSection)
                    
                    FillupsCard(vehicle: vehicle, activesheet: $activeSheet, selectedSection: $selectedSection)
                }
                
//                TipView(DashboardTip())
//                    .tipBackground(Color(.tertiarySystemBackground))
//                    .tint(Color.accent)
                
                CustomInfoSection(vehicle: vehicle, columns: columns, activeSheet: $activeSheet)
                    .padding(.top, 30)
            }
            .padding(.horizontal)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(vehicle.name)
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
                    AddEditVehicleView(vehicle: vehicle)
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
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if let newOdometer = newOdometerValue {
                        draftVehicle.odometer = newOdometer
                        vehicle.updateAndSave(draftVehicle: draftVehicle)
                    }
                }
                .disabled(newOdometerValue == nil)
            })
            .toolbar {
                vehicleToolbar
            }
        }
    }
    
    private var odometerDashboardCard: some View {
        DashboardCard(title: "Odometer", systemImage: "car.fill", accentColor: Color.accent, buttonLabel: "Update Odometer", buttonSymbol: "pencil") {
            showingUpdateOdometerAlert = true
        } content: {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(vehicle.odometer.formatted())")
                    .font(.headline)
                
                Text(settings.distanceUnit.abbreviated)
                    .font(.footnote.bold())
                    .foregroundStyle(Color.secondary)
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
                        Label("Activity Timeline", systemImage: "list.bullet")
                        Text("Maintenance and Repairs")
                    }
                }
                
                exportMenu
                
                Divider()
                
                Button("Edit Vehicle", systemImage: "pencil") { activeSheet = .editVehicle }
                
                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Label("Delete Vehicle", systemImage: "trash")
                        .tint(Color.red)
                }
            }
            .adaptiveTint()
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
                Button("Maintenance and Repairs") { showingPageSizeSelector = true }
            }
            
            Section("Spreadsheet (CSV)") {
                csvExportButton(title: "All Records") { CSVExporter.exportAllRecords(for: vehicle) }
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
        .environmentObject(AppSettings())
}
