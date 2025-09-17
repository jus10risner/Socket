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
        get { Int(odometer_) }
        set { odometer_ = Int64(newValue) }
    }
    
//    var colorComponents: [CGFloat]? {
//        get { colorComponents_ ?? [0.3060232996940613, 0.2939836084842682, 0.4549291133880615, 1.0] }
//        set { colorComponents_ = newValue }
//    }
    var colorComponents: [CGFloat]? {
        get {
            guard let nsArray = colorComponents_ else {
                return [0.306, 0.294, 0.455, 1.0]
            }
            
            return nsArray.compactMap { element in
                (element as? NSNumber).map { CGFloat(truncating: $0) }
            }
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
        let serviceEntries = servicesSet
            .flatMap { $0.sortedServiceRecordsArray }
            .map { record in
                VehicleExportRecord(
                    date: Calendar.current.startOfDay(for: record.date),
                    odometer: record.odometer,
                    type: .service(record)
                )
            }

        let repairsSet = repairs as? Set<Repair> ?? []
        let repairEntries = repairsSet
            .map { record in
                VehicleExportRecord(
                    date: Calendar.current.startOfDay(for: record.date),
                    odometer: record.odometer,
                    type: .repair(record)
                )
            }

        return (serviceEntries + repairEntries)
            .sorted {
                if $0.date != $1.date {
                    return $0.date > $1.date // most recent first
                } else {
                    return $0.odometer > $1.odometer
                }
            }
    }
    
    // Groups all service records and repairs by date (most recent first) and sorts alphabetically by service/repair name
    var groupedServiceAndRepairTimeline: [(date: Date, entries: [VehicleExportRecord])] {
        let allEntries = serviceAndRepairTimeline

        // Group entries by date
        let grouped = Dictionary(grouping: allEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }

        var result: [(date: Date, entries: [VehicleExportRecord])] = []

        for (date, entries) in grouped {
            let sortedEntries = entries.sorted { a, b in
                switch (a.type, b.type) {
                case (.service(let s1), .service(let s2)):
                    return (s1.service?.name ?? "") < (s2.service?.name ?? "")
                case (.repair(let r1), .repair(let r2)):
                    return r1.name < r2.name
                case (.service, .repair):
                    return true
                case (.repair, .service):
                    return false
                }
            }

            result.append((date: date, entries: sortedEntries))
        }

        // Sort by date
        return result.sorted { $0.date > $1.date }
    }
    
    
    
    // MARK: - CRUD Methods
    
    func updateAndSave(draftVehicle: DraftVehicle) {
        let context = DataController.shared.container.viewContext
        let colorComponents = UIColor(draftVehicle.selectedColor).cgColor.components
        
        self.name = draftVehicle.name
        self.odometer = draftVehicle.odometer ?? 0
        self.colorComponents = colorComponents
        self.photo = draftVehicle.photo
        
        self.updateAllServiceNotifications()
        
        try? context.save()
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
        
        // Add a baseline service log, if the user does not add their own service record (allows service alerts to work even for new vehicles where service has not yet been performed)
        if isBaseLine {
            let baselineLog = ServiceLog(context: context)
            baselineLog.id = UUID()
            baselineLog.date = draftServiceLog.date
            baselineLog.odometer = draftServiceLog.odometer ?? self.odometer
            baselineLog.isBaseline = true
            
            serviceRecord.serviceLog = baselineLog
        }
        
        self.updateAllServiceNotifications()
        
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
        
        if let odometer = draftRepair.odometer, odometer > self.odometer {
            self.odometer = odometer
            self.updateAllServiceNotifications()
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
        
        if let odometer = draftFillup.odometer, odometer > self.odometer {
            self.odometer = odometer
            self.updateAllServiceNotifications()
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
        
        try? context.save()
    }
    
    
    // MARK: - Other Methods
    
    // Checks to see when all notifications are due for this vehicle, and schedules them if necessary
    func updateAllServiceNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { permissions in
            guard permissions.authorizationStatus == .authorized else {
                print("Notifications not authorized.")
                return
            }

            for service in self.sortedServicesArray {
                service.updateNotifications(vehicle: self)
            }
        }
    }
}
