//
//  Vehicle+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import CoreData
import SwiftUI

extension Vehicle {
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }
    
    var odometer: Int {
        get { displayedDistance(fromStored: odometer_) }
        set { odometer_ = storedDistance(fromDisplayed: newValue) }
    }

    var lastOdometerLogAt: Date? {
        get { lastOdometerLogAt_ }
        set { lastOdometerLogAt_ = newValue }
    }

    func recordOdometerActivity(at date: Date = .now) {
        lastOdometerLogAt = date
    }

    var usesCanonicalMeasurements: Bool { measurementStorageVersion >= 1 }

    var distanceUnit: DistanceUnits {
        get { DistanceUnits(rawValue: distanceUnit_ ?? "") ?? AppSettingsStore.shared.distanceUnit }
        set { distanceUnit_ = newValue.rawValue }
    }

    var volumeUnit: VolumeUnits {
        get { VolumeUnits(rawValue: volumeUnit_ ?? "") ?? AppSettingsStore.shared.volumeUnit }
        set { volumeUnit_ = newValue.rawValue }
    }

    var fuelEconomyUnit: FuelEconomyUnits {
        get { FuelEconomyUnits(rawValue: fuelEconomyUnit_ ?? "") ?? AppSettingsStore.shared.fuelEconomyUnit }
        set { fuelEconomyUnit_ = newValue.rawValue }
    }

    func captureLegacyMeasurementUnitsIfNeeded(
        distanceUnit: DistanceUnits,
        volumeUnit: VolumeUnits,
        fuelEconomyUnit: FuelEconomyUnits
    ) {
        guard !usesCanonicalMeasurements else { return }
        if distanceUnit_ == nil { self.distanceUnit = distanceUnit }
        if volumeUnit_ == nil { self.volumeUnit = volumeUnit }
        if fuelEconomyUnit_ == nil { self.fuelEconomyUnit = fuelEconomyUnit }
    }

    func markMeasurementsAsCanonical() {
        measurementStorageVersion = 1
    }

    func displayedDistance(fromStored value: Int64) -> Int {
        guard usesCanonicalMeasurements else { return Int(value) }
        return Int(MeasurementConverter.distance(
            fromKilometers: Double(value),
            unit: distanceUnit
        ).rounded())
    }

    func storedDistance(fromDisplayed value: Int) -> Int64 {
        guard usesCanonicalMeasurements else { return Int64(value) }
        return Int64(MeasurementConverter.kilometers(
            from: Double(value),
            unit: distanceUnit
        ).rounded())
    }
    
    var colorComponents: [CGFloat]? {
        get {
            (colorComponents_ as? [NSNumber])?.map { CGFloat(truncating: $0) }
        }
        set {
            colorComponents_ = newValue?.map { NSNumber(value: Double($0)) } as NSArray?
        }
    }
    
    var backgroundColor: Color {
        if let colorComponents {
            return Color(.sRGB, red: colorComponents[0], green: colorComponents[1], blue: colorComponents[2], opacity: colorComponents[3])
        } else {
            return Color.socketPurple
        }
    }
    
    var sortedCustomInfoArray: [CustomInfo] {
        let set = customInfo as? Set<CustomInfo> ?? []
        
        return set.sorted {
            $0.label < $1.label
        }
    }
    
    var sortedRepairsArray: [Repair] {
        let set = repairs as? Set<Repair> ?? []
        
        return set.sorted {
            $0.date > $1.date
        }
    }
    
    var sortedFillupsArray: [Fillup] {
        let set = fillups as? Set<Fillup> ?? []
        
        return set.sorted {
            $0.date > $1.date
        }
    }
    
    // Returns an array of services, sorted by the order in which they are due (normalized by estimated days until due); uses name and id as fallbacks, if due dates are equal
    var sortedServicesArray: [Service] {
        let set = services as? Set<Service> ?? []
        
        return set.sorted { s1, s2 in
            switch (s1.estimatedDaysUntilDue(currentOdometer: odometer),
                    s2.estimatedDaysUntilDue(currentOdometer: odometer)) {
            case let (d1?, d2?):
                if d1 != d2 {
                    return d1 < d2
                } else if s1.name != s2.name {
                    return s1.name < s2.name
                } else {
                    return s1.id < s2.id
                }
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                if s1.name != s2.name {
                    return s1.name < s2.name
                } else {
                    return s1.id < s2.id
                }
            }
        }
    }

    
    // Returns all service records and repairs for this vehicle, sorted by date (most recent first)
    var serviceAndRepairTimeline: [VehicleExportRecord] {
        let servicesSet = services as? Set<Service> ?? []
        var entries: [VehicleExportRecord] = []

        // Collect all ServiceLogs from the service records
        let logsSet: Set<ServiceLog> = Set(
            servicesSet
                .flatMap(\.serviceHistoryRecordsArray)
                .compactMap { $0.serviceLog }
        )

        for log in logsSet {
            entries.append(
                VehicleExportRecord(
                    date: Calendar.current.startOfDay(for: log.date),
                    odometer: log.odometer,
                    type: .serviceLog(log)
                )
            )
        }

        // Add legacy ServiceRecords (not in a ServiceLog)
        let legacyRecords = servicesSet
            .flatMap(\.serviceHistoryRecordsArray)
            .filter { $0.serviceLog == nil }

        for record in legacyRecords {
            entries.append(
                VehicleExportRecord(
                    date: Calendar.current.startOfDay(for: record.date),
                    odometer: record.odometer,
                    type: .serviceRecord(record)
                )
            )
        }

        // Add Repairs
        let repairsSet = repairs as? Set<Repair> ?? []
        for repair in repairsSet {
            entries.append(
                VehicleExportRecord(
                    date: Calendar.current.startOfDay(for: repair.date),
                    odometer: repair.odometer,
                    type: .repair(repair)
                )
            )
        }

        // Sort by date descending, then odometer descending
        return entries.sorted {
            if $0.date != $1.date {
                return $0.date > $1.date
            } else {
                return $0.odometer > $1.odometer
            }
        }
    }
    
    // Groups all service records and repairs by date (most recent first) and sorts alphabetically by service/repair name
    var groupedServiceAndRepairTimeline: [(date: Date, entries: [VehicleExportRecord])] {
        let allEntries = serviceAndRepairTimeline

        let grouped = Dictionary(grouping: allEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }

        var result: [(date: Date, entries: [VehicleExportRecord])] = []

        for (date, entries) in grouped {
            let sortedEntries = entries.sorted { a, b in
                a.displayName < b.displayName
            }
            result.append((date: date, entries: sortedEntries))
        }

        return result.sorted { $0.date > $1.date }
    }
    
    
    
    // MARK: - CRUD Methods
    
    @discardableResult
    func updateAndSave(draftVehicle: DraftVehicle) -> Bool {
        guard let context = managedObjectContext else { return false }
        let colorComponents = UIColor(draftVehicle.selectedColor).cgColor.components
        let originalDisplayedOdometer = odometer
        let originalDistanceUnit = distanceUnit
        let expectedUneditedOdometer = Int(MeasurementConverter.distance(
            fromKilometers: MeasurementConverter.kilometers(
                from: Double(originalDisplayedOdometer),
                unit: originalDistanceUnit
            ),
            unit: draftVehicle.distanceUnit
        ).rounded())
        let odometerWasEdited = draftVehicle.odometer != expectedUneditedOdometer
        
        self.name = draftVehicle.name
        if !usesCanonicalMeasurements, draftVehicle.shouldMigrateMeasurements {
            migrateMeasurements(
                from: draftVehicle.legacyDistanceUnit,
                volumeUnit: draftVehicle.legacyVolumeUnit
            )
        }
        distanceUnit = draftVehicle.distanceUnit
        volumeUnit = draftVehicle.volumeUnit
        fuelEconomyUnit = draftVehicle.fuelEconomyUnit
        if odometerWasEdited, let odometer = draftVehicle.odometer {
            self.odometer = odometer
            recordOdometerActivity()
        }
        self.colorComponents = colorComponents
        self.photo = draftVehicle.photo
        
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            print("⚠️ Failed to save vehicle: \(error.localizedDescription)")
            return false
        }
    }

    func migrateMeasurements(from distanceUnit: DistanceUnits, volumeUnit: VolumeUnits) {
        odometer = canonicalDistance(odometer, from: distanceUnit)

        for fillup in fillups as? Set<Fillup> ?? [] {
            fillup.odometer = canonicalDistance(fillup.odometer, from: distanceUnit)
            fillup.volume = MeasurementConverter.liters(from: fillup.volume, unit: volumeUnit)
            fillup.pricePerUnit = MeasurementConverter.pricePerLiter(
                from: fillup.pricePerUnit ?? 0,
                unit: volumeUnit
            )
        }

        for repair in repairs as? Set<Repair> ?? [] {
            repair.odometer = canonicalDistance(repair.odometer, from: distanceUnit)
        }

        var migratedLogs = Set<NSManagedObjectID>()
        for service in services as? Set<Service> ?? [] {
            service.distanceInterval = canonicalDistance(service.distanceInterval, from: distanceUnit)
            if let scheduledOdometer = service.lastScheduledNotificationOdometer {
                service.lastScheduledNotificationOdometer = canonicalDistance(scheduledOdometer, from: distanceUnit)
            }

            for record in service.serviceRecords as? Set<ServiceRecord> ?? [] {
                record.odometer = canonicalDistance(record.odometer, from: distanceUnit)
                if let log = record.serviceLog, migratedLogs.insert(log.objectID).inserted {
                    log.odometer = canonicalDistance(log.odometer, from: distanceUnit)
                }
            }
        }

        markMeasurementsAsCanonical()
    }

    private func canonicalDistance(_ value: Int, from unit: DistanceUnits) -> Int {
        Int(MeasurementConverter.kilometers(from: Double(value), unit: unit).rounded())
    }
    
    func addNewService(draftService: DraftService, initialRecord draftServiceLog: DraftServiceLog, isBaseLine: Bool) {
        let context = DataController.shared.container.viewContext
        
        // Create Service
        let newService = Service(context: context)
        newService.vehicle = self
        newService.id = UUID()
        newService.name = draftService.name
        newService.distanceInterval = draftService.distanceInterval ?? 0
        newService.timeInterval = draftService.timeInterval ?? 0
        newService.monthsInterval = draftService.monthsInterval
        newService.note = draftService.serviceNote
        newService.distanceBasedNotificationIdentifier = UUID().uuidString
        newService.timeBasedNotificationIdentifier = UUID().uuidString
        
        // Add Service Record to Service
        let serviceRecord = ServiceRecord(context: context)
        serviceRecord.service = newService
        serviceRecord.id = UUID()
        serviceRecord.date = draftServiceLog.date
        serviceRecord.odometer = draftServiceLog.odometer ?? self.odometer
        serviceRecord.cost = draftServiceLog.cost ?? 0.0
        
        // Add a baseline service log, if the user does not add their own service record (allows service alerts to work even for new vehicles where service has not yet been performed)
        if isBaseLine {
            let baselineLog = ServiceLog(context: context)
            baselineLog.id = UUID()
            baselineLog.date = draftServiceLog.date
            serviceRecord.serviceLog = baselineLog
            let displayedOdometer = draftServiceLog.odometer ?? self.odometer
            baselineLog.odometer = displayedOdometer
            baselineLog.isBaseline = true
        }
        
        try? context.save()
    }
    
    func addNewRepair(draftRepair: DraftRepair) {
        let context = DataController.shared.container.viewContext
        let newRepair = Repair(context: context)
        newRepair.vehicle = self
        newRepair.id = UUID()
        newRepair.date = draftRepair.date
        newRepair.name = draftRepair.name
        newRepair.odometer = draftRepair.odometer ?? 0
        newRepair.cost = draftRepair.cost
        newRepair.note = draftRepair.note
        newRepair.photos = NSSet(array: draftRepair.photos)
        newRepair.documents = NSSet(array: draftRepair.documents)
        if draftRepair.odometer != nil {
            recordOdometerActivity()
        }
        
        if let odometer = draftRepair.odometer, odometer > self.odometer {
            self.odometer = odometer
//            self.updateAllServiceNotifications()
        }
        
        try? context.save()
    }
    
    func addNewFillup(draftFillup: DraftFillup) {
        let context = DataController.shared.container.viewContext
        let newFillup = Fillup(context: context)
        newFillup.vehicle = self
        newFillup.id = UUID()
        newFillup.date = draftFillup.date
        newFillup.odometer = draftFillup.odometer ?? 0
        newFillup.volume = draftFillup.volume ?? 0
        newFillup.pricePerUnit = draftFillup.fillupCostPerUnit
        newFillup.fillType = draftFillup.fillType
        newFillup.note = draftFillup.note
        newFillup.photos = NSSet(array: draftFillup.photos)
        newFillup.documents = NSSet(array: draftFillup.documents)
        if draftFillup.odometer != nil {
            recordOdometerActivity()
        }
        
        if let odometer = draftFillup.odometer, odometer > self.odometer {
            self.odometer = odometer
//            self.updateAllServiceNotifications()
        }
        
        try? context.save()
    }
    
    func addNewInfo(draftCustomInfo: DraftCustomInfo) {
        let context = DataController.shared.container.viewContext
        let newCustomInfo = CustomInfo(context: context)
        newCustomInfo.vehicle = self
        newCustomInfo.id = UUID()
        newCustomInfo.label = draftCustomInfo.label
        newCustomInfo.detail = draftCustomInfo.detail
        newCustomInfo.note = draftCustomInfo.note
        newCustomInfo.photos = NSSet(array: draftCustomInfo.photos)
        newCustomInfo.documents = NSSet(array: draftCustomInfo.documents)
        
        try? context.save()
    }
}
