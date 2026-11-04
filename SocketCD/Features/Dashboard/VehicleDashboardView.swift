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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject var draftVehicle = DraftVehicle()
    @ObservedObject var vehicle: Vehicle
    @Binding var selectedVehicle: Vehicle? // Used primarily to dismiss this view if the vehicle is deleted
    let settings = AppSettingsStore.shared
    
    init(vehicle: Vehicle, selectedVehicle: Binding<Vehicle?>) {
        _draftVehicle = StateObject(wrappedValue: DraftVehicle(vehicle: vehicle))
        self.vehicle = vehicle
        self._selectedVehicle = selectedVehicle
        _dashboardSections = State(initialValue: DashboardLayoutStore().load(for: vehicle.id))
    }
    
    @State private var selectedSection: AppSection?
    @State private var activeSheet: ActiveSheet?
    @State private var servicesForNewLog: [Service] = []
    @State private var showingUpdateOdometerAlert = false
    @State private var newOdometerValue = ""
    @State private var pendingOdometer: Int?
    @State private var odometerWarning: OdometerWarning?
    @State private var isVehicleNameInToolbar = false
    @State private var dashboardSections: [DashboardSectionPreference] = .dashboardDefaults
    @State private var showingDashboardCustomization = false

    @State private var shareItem: ShareItem?
    @State private var showingExportOptions = false
    @State private var showingExportError = false
    @State private var showingCSVExportOptions = false
    @State private var pendingCSVOptions: CSVExportOptions?

    private let minimumColumnWidth: CGFloat = 325
    private let maximumGridWidth: CGFloat = 800
    private let gridSpacing: CGFloat = 5
    
    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            [GridItem(.flexible(), alignment: .top)]
        } else {
            [
                GridItem(
                    .adaptive(minimum: minimumColumnWidth),
                    spacing: gridSpacing,
                    alignment: .top
                )
            ]
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                TipView(DashboardTip())
                    .tipBackground(Color(.tertiarySystemBackground))
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(vehicle.name)
                                .font(.title3.bold())
                                .opacity(isVehicleNameInToolbar ? 0 : 1)
                                .accessibilityHidden(isVehicleNameInToolbar)
                                .onGeometryChange(for: Bool.self) { proxy in
                                    proxy.frame(in: .scrollView(axis: .vertical)).maxY <= 0
                                } action: { isBehindToolbar in
                                    isVehicleNameInToolbar = isBehindToolbar
                                }

                            HStack(spacing: 10) {
                                Text(
                                    "\(Text(vehicle.odometer.formatted()).font(.title.bold()).monospacedDigit()) \(Text(vehicle.distanceUnit.abbreviated).font(.title3.bold()).foregroundColor(.secondary))"
                                )
                                .contentTransition(.numericText(value: Double(vehicle.odometer)))
                                .animation(.default, value: vehicle.odometer)
                                .accessibilityLabel("Odometer: \(vehicle.odometer.formatted()) \(vehicle.distanceUnit.abbreviated)")
                                 
                                Button("Update Odometer", systemImage: "pencil") {
                                    showingUpdateOdometerAlert = true
                                }
                                .imageScale(.large)
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.circle)
                                .dynamicTypeSize(.medium)
                            }
                        }
                        
                        Spacer()
                    }

                    DashboardCardGrid(
                        sections: dashboardSections,
                        columns: columns,
                        spacing: gridSpacing,
                        vehicle: vehicle,
                        activeSheet: $activeSheet,
                        selectedSection: $selectedSection,
                        servicesForNewLog: $servicesForNewLog
                    )
                    
                    HStack {
                        Button("Edit Dashboard") {
                            showingDashboardCustomization = true
                        }
                        
                        NavigationLink("View All Activity") {
                            VehicleActivityView(vehicle: vehicle)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: maximumGridWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(vehicle.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedSection) { section in
                destinationView(for: section, vehicle: vehicle)
            }
            .navigationDestination(isPresented: $showingDashboardCustomization) {
                DashboardCustomizationView(
                    preferences: $dashboardSections,
                    vehicleID: vehicle.id
                )
            }
            .sheet(item: $activeSheet, onDismiss: refreshDashboard) { sheet in
                switch sheet {
                case .logService:
                    AddEditRecordView(services: servicesForNewLog, vehicle: vehicle)
                case .addRepair:
                    AddEditRepairView(vehicle: vehicle)
                case .addFillup:
                    AddEditFillupView(vehicle: vehicle)
                case .addCustomInfo:
                    AddEditCustomInfoView(vehicle: vehicle)
                case .editVehicle:
                    AddEditVehicleView(vehicle: vehicle, onDelete: { selectedVehicle = nil })
                }
            }
            .sensoryFeedback(trigger: activeSheet) { _, newSheet in
                switch newSheet {
                case .logService, .addRepair, .addFillup, .addCustomInfo:
                    return .impact(weight: .light)
                case .editVehicle, nil:
                    return nil
                }
            }
            .sheet(item: $shareItem) { item in
                ActivityView(activityItems: [item.url])
            }
            .sheet(isPresented: $showingExportOptions) {
                PDFExportOptionsView { options in
                    exportPDF(options: options)
                }
                .presentationBackground(Color(.systemBackground))
            }
            .sheet(isPresented: $showingCSVExportOptions, onDismiss: exportPendingCSV) {
                CSVExportOptionsView { options in
                    pendingCSVOptions = options
                }
                .presentationBackground(Color(.systemBackground))
            }
            .tint(settings.selectedAccent())
            .alert("Update Odometer", isPresented: $showingUpdateOdometerAlert, actions: {
                TextField("\(draftVehicle.odometer ?? 0)", text: $newOdometerValue)
                    .keyboardType(.numberPad)
                    .onChange(of: newOdometerValue) { _, newValue in
                        formatOdometerInput(newValue)
                    }
                
                Button("Cancel", role: .cancel) {
                    newOdometerValue = ""
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Update") {
                    validateEnteredOdometer()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(enteredOdometer == nil)
            })
            .odometerWarningAlert(
                warning: $odometerWarning,
                entered: pendingOdometer,
                current: vehicle.odometer,
                distanceUnit: vehicle.distanceUnit.abbreviated,
                confirmationTitle: "Update Anyway",
                cancellationTitle: "Cancel",
                onConfirm: commitPendingOdometer,
                onCancel: { pendingOdometer = nil }
            )
            .alert("Couldn’t Export Records", isPresented: $showingExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The document couldn’t be created. Please try again.")
            }
            .toolbar {
                vehicleToolbar
            }
            .onChange(of: vehicle.objectID) {
                isVehicleNameInToolbar = false
                dashboardSections = DashboardLayoutStore().load(for: vehicle.id)
            }
        }
        .tint(nil)
        .onAppear {
            dashboardSections = DashboardLayoutStore().load(for: vehicle.id)
        }
    }

    private var enteredOdometer: Int? {
        Int(newOdometerValue.filter(\.isNumber))
    }

    private func formatOdometerInput(_ input: String) {
        let digits = input.filter(\.isNumber)
        let formattedValue = Int(digits)?.formatted() ?? digits

        if newOdometerValue != formattedValue {
            newOdometerValue = formattedValue
        }
    }

    private func validateEnteredOdometer() {
        guard let enteredOdometer else { return }

        pendingOdometer = enteredOdometer
        newOdometerValue = ""

        if let warning = OdometerValidator.warning(
            entered: enteredOdometer,
            current: vehicle.odometer,
            context: .currentVehicle
        ) {
            DispatchQueue.main.async {
                odometerWarning = warning
            }
        } else {
            commitPendingOdometer()
        }
    }

    private func commitPendingOdometer() {
        guard let pendingOdometer else { return }

        draftVehicle.odometer = pendingOdometer
        vehicle.updateAndSave(draftVehicle: draftVehicle)
        self.pendingOdometer = nil
    }

    private func refreshDashboard() {
        withAnimation {
            vehicle.objectWillChange.send()
        }
    }
    
    @ToolbarContentBuilder
    private var vehicleToolbar: some ToolbarContent {
        ToolbarItem {
            Menu("Vehicle Options", systemImage: "ellipsis") {
                exportMenu
                
                Divider()
                
                Button("Edit Vehicle", systemImage: "pencil") { activeSheet = .editVehicle }
            }
            .adaptiveTint()
        }

        ToolbarItem(placement: .principal) {
            Text(vehicle.name)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .opacity(isVehicleNameInToolbar ? 1 : 0)
                .accessibilityHidden(!isVehicleNameInToolbar)
                .animation(.easeInOut(duration: 0.2), value: isVehicleNameInToolbar)
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
    
    private func exportPendingCSV() {
        guard let options = pendingCSVOptions else { return }
        pendingCSVOptions = nil
        do {
            let url = try CSVExporter.export(vehicle: vehicle, options: options)
            shareItem = ShareItem(url: url)
        } catch {
            showingExportError = true
        }
    }

    // Menu, including buttons for exporting/sharing vehicle records.
    private var exportMenu: some View {
        Menu("Export", systemImage: "square.and.arrow.up") {
            Button {
                showingExportOptions = true
            } label: {
                Label("Vehicle History", systemImage: "document")
                Text("PDF Report")
            }
            
            Button {
                showingCSVExportOptions = true
            } label: {
                Label("Raw Data", systemImage: "tablecells")
                Text("CSV Spreadsheets")
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

private struct DashboardCardGrid: View {
    let sections: [DashboardSectionPreference]
    let columns: [GridItem]
    let spacing: CGFloat
    @ObservedObject var vehicle: Vehicle
    @Binding var activeSheet: ActiveSheet?
    @Binding var selectedSection: AppSection?
    @Binding var servicesForNewLog: [Service]

    private var visibleSections: [DashboardSectionPreference] {
        sections.filter(\.isVisible)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(visibleSections) { preference in
                switch preference.section {
                case .maintenance:
                    MaintenanceCard(
                        vehicle: vehicle,
                        activeSheet: $activeSheet,
                        selectedSection: $selectedSection,
                        servicesForNewLog: $servicesForNewLog
                    )
                case .repairs:
                    RepairsCard(
                        vehicle: vehicle,
                        activeSheet: $activeSheet,
                        selectedSection: $selectedSection
                    )
                case .fillups:
                    FillupsCard(
                        vehicle: vehicle,
                        activesheet: $activeSheet,
                        selectedSection: $selectedSection
                    )
                case .customInfo:
                    CustomInfoCard(
                        vehicle: vehicle,
                        activeSheet: $activeSheet,
                        selectedSection: $selectedSection
                    )
                }
            }
        }
    }
}

// Sheet options for VehicleDashboardView
enum ActiveSheet: String, Identifiable {
    case logService, addRepair, addFillup, addCustomInfo, editVehicle
    
    var id: String { rawValue }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleDashboardView(vehicle: vehicle, selectedVehicle: .constant(vehicle))
}
