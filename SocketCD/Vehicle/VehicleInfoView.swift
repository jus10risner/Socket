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
    @State private var showingAddCustomInfo = false
    @State private var showingConfirmationDialog = false
    @State private var showingActivityView = false
    
    @State var documentURL: URL?
    
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
            .onChange(of: vehicle.odometer) { _ in
                vehicle.determineIfNotificationDue()
            }
            .sheet(isPresented: $showingEditVehicle) { EditVehicleView(vehicle: vehicle) }
            
          // Sheet wasn't loading the url on first launch of ActivityView, so I manually added a getter/setter. Issue resolved.
            .sheet(isPresented: Binding(
                get: { showingActivityView },
                set: { showingActivityView = $0 }
            )) {
                ActivityView(activityItems: [documentURL as Any], applicationActivities: nil)
            }
            .sheet(isPresented: $showingAddCustomInfo) { AddCustomInfoView(vehicle: vehicle) }
//            .confirmationDialog("How would you like to share your records?", isPresented: $showingConfirmationDialog, titleVisibility: .visible) {
//                Button("Printable Summary (PDF)") {
//                    createMaintenanceRepairsPDF()
//                    showingActivityView = true
//                }
//                
//                Button("Spreadsheet File (CSV)") {
//                    createMaintenanceRepairsCSV()
//                    showingActivityView = true
//                }
//            } message: {
//                Text("Attached images will not be included.")
//            }
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
                        
                        Menu {
                            Section("Printable Summary (PDF)") {
                                Button("Maintenance & Repairs") {
                                    createMaintenanceRepairsPDF()
                                    showingActivityView = true
                                }
                            }
                            .accessibilityHint("Share maintenance and repair records for this vehicle")
                            
                            Section("Spreadsheet Document (CSV)") {
                                Button("Maintenance & Repairs") {
                                    createMaintenanceRepairsCSV()
                                    showingActivityView = true
                                }
                                
                                Button("Fill-ups") {
                                    createFillupsCSV()
                                    showingActivityView = true
                                }
                                .accessibilityHint("Share fill-up records for this vehicle, in csv format")
                            }
                        } label: {
                            Label("Share Records", systemImage: "square.and.arrow.up")
                        }
                        
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
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("\(vehicle.odometer) \(settings.shortenedDistanceUnit)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity)
        .listRowInsets(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    // Displays any additional vehicle info added by the user
    private var customInfoSection: some View {
        Section(footer: addInfoButton) {
            if vehicle.sortedCustomInfoArray.isEmpty {
                Text("Add additional vehicle info (VIN, license plate, etc.) here, for easy reference.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.vertical, 10)
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
        }
    }
    
    // Button component, for adding custom vehicle info
    private var addInfoButton: some View {
        Button {
            showingAddCustomInfo = true
        } label: {
            Label("Add Vehicle Info", systemImage: "plus.square")
                .font(.body)
                .frame(maxWidth: .infinity)
                .padding(10)
                .accessibilityHint("Add additional information about this vehicle")
        }
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
