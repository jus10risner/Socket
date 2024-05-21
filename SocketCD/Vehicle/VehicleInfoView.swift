//
//  VehicleInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct VehicleInfoView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var vehicle: Vehicle
    
    @FetchRequest var customInfo: FetchedResults<CustomInfo>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._customInfo = FetchRequest(
            entity: CustomInfo.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \CustomInfo.label_, ascending: true)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var showingEditVehicle = false
    @State private var showingDeleteAlert = false
    @State private var showingMoreInfo = false
    @State private var showingAddCustomInfo = false
    @State private var showingConfirmationDialog = false
    @State private var showingActivityView = false
    
    @State private var documentURL: URL?
    
    var body: some View {
        vehicleInfo
    }
    
    
    // MARK: - Views
    
    private var vehicleInfo: some View {
        AppropriateNavigationType {
            List {
                vehicleDetailsSection
                
                customInfoSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: vehicle.odometer) { _ in
                vehicle.determineIfNotificationDue()
            }
            .sheet(isPresented: $showingEditVehicle) { EditVehicleView(vehicle: vehicle) }
            
          // Sheet wasn't loading the url on first launch of ActivityView, so I manually added a getter/setter. This seems to have resolved the issue.
            .sheet(isPresented: Binding(
                get: { showingActivityView },
                set: { showingActivityView = $0 }
            )) {
                ActivityView(activityItems: [documentURL as Any], applicationActivities: nil)
            }
            .sheet(isPresented: $showingAddCustomInfo) { AddCustomInfoView(vehicle: vehicle) }
            .confirmationDialog("Permanently delete \(vehicle.name) and all of its records? \nThis action cannot be undone.", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    vehicle.delete()
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .toolbar {
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
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingEditVehicle = true
                        } label: {
                            Label("Edit Vehicle", systemImage: "pencil")
                        }
                        
                        exportMenu
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Vehicle", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityLabel("Vehicle Options")
                    }
                }
            }
        }
    }
    
    // Menu, including buttons for exporting/sharing vehicle records. iOS 15 doesn't display section headers in menus, so there's some conditional logic for showing the appropriate header style
    private var exportMenu: some View {
        Menu {
            Section {
                if #unavailable (iOS 16) {
                    Text("Maintenance & Repairs")
                        .foregroundStyle(Color.secondary)
                }
                
                Button {
                    createMaintenanceRepairsPDF()
                    showingActivityView = true
                } label: {
                    Label("PDF", systemImage: "doc")
                }
                
                Button {
                    createMaintenanceRepairsCSV()
                    showingActivityView = true
                } label: {
                    Label("CSV", systemImage: "tablecells")
                }
            } header: {
                if #available(iOS 16, *) {
                    Text("Maintenance & Repairs")
                }
            }
            .accessibilityHint("Export maintenance and repair records for this vehicle")
            
            Section {
                if #unavailable (iOS 16) {
                    Text("Fill-ups")
                        .foregroundStyle(Color.secondary)
                }
                
                Button {
                    createFillupsCSV()
                    showingActivityView = true
                } label: {
                    Label("CSV", systemImage: "tablecells")
                }
            } header: {
                if #available(iOS 16, *) {
                    Text("Fill-ups")
                }
            }
            .accessibilityHint("Export fill-up records for this vehicle")
        } label: {
            Label("Export Records", systemImage: "square.and.arrow.up")
        }
    }
    
    // Includes the vehicle image, name, and odometer
    private var vehicleDetailsSection: some View {
        Section {
            VStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.clear)
                    .aspectRatio(2, contentMode: .fit)
                    .frame(height: 100)
                    .overlay(
                        ZStack {
                            if let carPhoto = vehicle.photo {
                                VehiclePhotoView(carPhoto: carPhoto)
                            } else {
                                PlaceholderPhotoView(backgroundColor: vehicle.backgroundColor)
                            }
                        }
                        .imageScale(.small)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.black.opacity(0.3), lineWidth: 0.25)
                            .foregroundStyle(Color.clear)
                    }
                    .listRowSeparator(.hidden)
                    .accessibilityHidden(true)
                
                VStack(spacing: 0) {
                    Text(vehicle.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("\(vehicle.odometer) \(settings.shortenedDistanceUnit)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    // Displays any additional vehicle info added by the user
    private var customInfoSection: some View {
        Section {
            if vehicle.sortedCustomInfoArray.isEmpty {
                VStack(spacing: 20) {
                    Text("Add things like your vehicle's VIN or license plate number here, for easy reference.")
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 3) {
                        Text("Tap")
                        
                        addInfoButton
                        
                        Text("to add vehicle info")
                    }
                    .frame(maxWidth: .infinity)
                }
                .font(.subheadline)
                .padding(.horizontal, 5)
                .padding(.vertical, 20)
            } else {
                ForEach(customInfo, id: \.id) { customInfo in
                    NavigationLink {
                        CustomInfoDetailView(customInfo: customInfo)
                    } label: {
                        Text(customInfo.label)
                    }
                }
//                .onDelete{ indexSet in
//                    for index in indexSet {
//                        context.delete(customInfo[index])
//                    }
//                    
//                    try? context.save()
//                }
            }
        } header: {
            HStack {
                Text("Additional Vehicle Info")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                addInfoButton
            }
        }
        .textCase(nil)
    }
    
    // Button component, for adding additional vehicle info
    private var addInfoButton: some View {
        Button {
            showingAddCustomInfo = true
        } label: {
            Label("Add Vehicle Info", systemImage: "plus.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.white, Color.selectedColor(for: .appTheme))
                .labelStyle(.iconOnly)
                .font(.title2)
        }
        .buttonStyle(.plain)
    }
    
    
    // MARK: - Methods
    
    // Creates PDF of Maintenance & Repair Records
    func createMaintenanceRepairsPDF() {
        let fileName = "\(vehicle.name) Records.pdf"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(fileName)
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        var allRecords: [String] = []

        var pdfHeader = "Maintenance & Repairs (as of \(Date.now.formatted(date: .numeric, time: .omitted)))\n\n"
        pdfHeader.append("Vehicle: \(vehicle.name)\n")
        pdfHeader.append("Odometer: \(vehicle.odometer.formatted()) \(settings.shortenedDistanceUnit)\n\n")
        
        // Append service records to allRecords array
        for service in vehicle.sortedServicesArray {
            for record in service.sortedServiceRecordsArray {
                let formattedDate = record.date.formatted(date: .numeric, time: .omitted)
                
                for item in allRecords {
                    if item.components(separatedBy: "\n").contains(formattedDate) {
                        if let itemIndex = allRecords.firstIndex(of: item) {
                            allRecords[itemIndex].append("    \(service.name)\(record.note != "" ? " - Note: \(record.note)\n" : "\n")")
                        }
                    }
                }
                   
                if !allRecords.contains(where: { $0.components(separatedBy: "\n").first! == formattedDate }) {
                    allRecords.append("\(formattedDate)\n    \(record.odometer.formatted()) \(settings.shortenedDistanceUnit)\n    \(service.name)\(record.note != "" ? " - Note: \(record.note)\n" : "\n")")
                }
            }
        }

        // Append repair records to allRecords array
        for repair in vehicle.sortedRepairsArray {
            let formattedDate = repair.date.formatted(date: .numeric, time: .omitted)
            
            for item in allRecords {
                if item.components(separatedBy: "\n").contains(formattedDate) {
                    if let itemIndex = allRecords.firstIndex(of: item) {
                        allRecords[itemIndex].append("    \(repair.name)\(repair.note != "" ? " - Note: \(repair.note)\n" : "\n")")
                    }
                }
            }
            
            if !allRecords.contains(where: { $0.components(separatedBy: "\n").first! == formattedDate }) {
                allRecords.append("\(formattedDate)\n    \(repair.odometer.formatted()) \(settings.shortenedDistanceUnit)\n    \(repair.name)\(repair.note != "" ? " - Note: \(repair.note)\n" : "\n")")
            }
        }
        
        for index in allRecords.indices {
            allRecords[index].append("\n")
        }
        
        // Convert String to Date, then append all records to pdfHeader
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MM/dd/yyyy")
        
        let sortedRecords = allRecords.sorted { df.date(from: $0.components(separatedBy: "\n").first ?? "") ?? Date.now > df.date(from: $1.components(separatedBy: "\n").first ?? "") ?? Date.now }.joined()

        pdfHeader.append(sortedRecords)
        
        // Render PDF document
        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            pdfHeader.draw(in: pageRect.insetBy(dx: 50, dy: 50))
        }

        // Save PDF document to temporary directory
        do {
            try data.write(to: fileURL)
            documentURL = fileURL
        } catch {
            print("Failed to create file: \(error)")
        }
    }
    
    // Creates CSV of Maintenance & Repair Records
    func createMaintenanceRepairsCSV() {
        let fileName = "\(vehicle.name) Records.csv"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(fileName)

        var allRecords: [String] = []

        var csvHeader = "Date, Odometer, Name, Cost, Note\n"

        // Append service records to allRecords array
        for service in vehicle.sortedServicesArray {
            for record in service.sortedServiceRecordsArray {
                allRecords.append("\(record.date.formatted(date: .numeric, time: .omitted)), \(record.odometer), \"\(service.name)\", \(String(format: "%.2f", record.cost ?? 0)), \"\(record.note)\"\n")
            }
        }
        
        // Append repair records to allRecords array
        for repair in vehicle.sortedRepairsArray {
            allRecords.append("\(repair.date.formatted(date: .numeric, time: .omitted)), \(repair.odometer), \"\(repair.name)\", \(String(format: "%.2f", repair.cost ?? 0)), \"\(repair.note)\"\n")
        }
        
        // Convert String to Date, then append all records to csvHeader
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MM/dd/yyyy")

        let sortedRecords = allRecords.sorted { df.date(from: $0.components(separatedBy: ",").first ?? "") ?? Date.now > df.date(from: $1.components(separatedBy: ",").first ?? "") ?? Date.now }.joined()

        csvHeader.append(sortedRecords)

        // Save CSV file to temporary directory
        do {
            try csvHeader.write(to: fileURL, atomically: true, encoding: .utf8)
            documentURL = fileURL
        } catch {
            print("Failed to create file: \(error)")
        }
    }
    
    // Creates CSV of Fill-up Records
    func createFillupsCSV() {
        let filename = "\(vehicle.name) Fill-ups.csv"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(filename)
        
        var allFillups: [String] = []
        
        var csvHeader = "Date, Odometer, \(vehicle.volumeUnit)s of Fuel, Price per \(vehicle.volumeUnit), Trip (\(settings.shortenedDistanceUnit)), Fuel Economy (\(settings.fuelEconomyUnit.rawValue)), Total Cost, Full Tank?, Note\n"

        // Append fill-up records to allFillups array
        for fillup in vehicle.sortedFillupsArray {
            allFillups.append("\(fillup.date.formatted(date: .numeric, time: .omitted)), \(fillup.odometer), \(fillup.volume.formatted()), \((fillup.pricePerUnit ?? 0).formatted()), \"\(fillup.tripDistance)\", \(String(format: "%.1f", fillup.fuelEconomy)), \(String(format: "%.2f", fillup.totalCost ?? 0)), \(fillup.fillType == .partialFill ? "No" : "Yes"), \"\(fillup.note)\"\n")
        }
        
        // Convert String to Date, then append all records to csvHeader
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MM/dd/yyyy")
        
        let sortedFillups = allFillups.sorted { df.date(from: $0.components(separatedBy: ",").first ?? "") ?? Date.now > df.date(from: $1.components(separatedBy: ",").first ?? "") ?? Date.now }.joined()
        
        csvHeader.append(sortedFillups)
        
        // Save CSV file to temporary directory
        do {
            try csvHeader.write(to: fileURL, atomically: true, encoding: .utf8)
            documentURL = fileURL
        } catch {
            print("Failed to create file: \(error)")
        }
    }
}

#Preview {
    VehicleInfoView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
