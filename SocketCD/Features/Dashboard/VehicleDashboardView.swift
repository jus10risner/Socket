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
    
    @State private var shareItem: ShareItem?
    @State private var showingExportOptions = false
    @State private var showingExportError = false
    
    let columns = [GridItem(.adaptive(minimum: 325), spacing: 5)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                TipView(DashboardTip())
                    .tipBackground(Color(.tertiarySystemBackground))
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(vehicle.name)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 10) {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(vehicle.odometer.formatted())
                                    .font(.title2.bold())
                                    .monospacedDigit()
                                
                                Text(settings.distanceUnit.abbreviated)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel("Odometer: \(vehicle.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                             
                            Button("Update Odometer", systemImage: "pencil") {
                                showingUpdateOdometerAlert = true
                            }
                            .imageScale(.large)
                            .labelStyle(.iconOnly)
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                        }
                    }
                    .padding(.top, 5)
                    
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
            .sheet(isPresented: $showingExportOptions) {
                PDFExportOptionsView { options in
                    exportPDF(options: options)
                }
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
            .alert("Couldn’t Export PDF", isPresented: $showingExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The document couldn’t be created. Please try again.")
            }
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
        }
    }
    
    private func exportPDF(options: PDFExportOptions) {
        Task {
            if let exportURL = PDFExporter.export(vehicle: vehicle, options: options) {
                shareItem = ShareItem(url: exportURL)
            } else {
                showingExportError = true
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
                Button("Maintenance and Repairs") { showingExportOptions = true }
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

private struct PDFExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("pdfExportPaperSize") private var paperSizeRawValue = PDFPaperSize.usLetter.rawValue
    @State private var options = PDFExportOptions()

    let export: (PDFExportOptions) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Paper Size") {
                    Picker("Paper Size", selection: paperSizeSelection) {
                        ForEach(PDFPaperSize.allCases) { paperSize in
                            Text(paperSize.title).tag(paperSize)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Toggle("Include Photos", isOn: $options.includePhotos)
                    Toggle("Include Costs", isOn: $options.includeCosts)
                    Toggle("Include Notes", isOn: $options.includeNotes)
                }
            }
            .navigationTitle("Export PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Export", systemImage: "checkmark") {
                        var selectedOptions = options
                        selectedOptions.paperSize = selectedPaperSize
                        dismiss()
                        export(selectedOptions)
                    }
                    .labelStyle(.adaptive)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var selectedPaperSize: PDFPaperSize {
        PDFPaperSize(rawValue: paperSizeRawValue) ?? .usLetter
    }

    private var paperSizeSelection: Binding<PDFPaperSize> {
        Binding(
            get: { selectedPaperSize },
            set: { paperSizeRawValue = $0.rawValue }
        )
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
