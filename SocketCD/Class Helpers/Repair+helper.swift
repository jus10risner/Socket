//
//  Repair+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData

extension Repair {
    var distanceUnit: DistanceUnits {
        vehicle?.distanceUnit ?? AppSettingsStore.shared.distanceUnit
    }

    
    var date: Date {
        get { date_ ?? Date() }
        set { date_ = newValue }
    }
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }

    var odometer: Int {
        get { vehicle?.displayedDistance(fromStored: odometer_) ?? Int(odometer_) }
        set { odometer_ = vehicle?.storedDistance(fromDisplayed: newValue) ?? Int64(newValue) }
    }

    var cost: Double? {
        get { cost_ }
        set { cost_ = newValue ?? 0 }
    }
    
    var note: String {
        get { note_ ?? "" }
        set { note_ = newValue }
    }
    
    var sortedPhotosArray: [Photo] {
        let set = photos as? Set<Photo> ?? []
        
        return set.sorted {
            $0.timeStamp < $1.timeStamp
        }
    }

    var sortedDocumentsArray: [AttachedDocument] {
        let set = documents as? Set<AttachedDocument> ?? []
        return set.sorted { $0.timeStamp < $1.timeStamp }
    }
    
    // MARK: - CRUD Methods
    
    func updateAndSave(draftRepair: DraftRepair) {
        let context = DataController.shared.container.viewContext
        
        self.date = draftRepair.date
        self.name = draftRepair.name
        self.category = draftRepair.category
        self.odometer = draftRepair.odometer ?? 0
        self.cost = draftRepair.cost
        self.note = draftRepair.note
        self.photos = NSSet(array: draftRepair.photos)
        self.documents = NSSet(array: draftRepair.documents)
        
        if let vehicle = self.vehicle, let draftOdometer = draftRepair.odometer, draftOdometer > vehicle.odometer {
            vehicle.odometer = draftOdometer
        }
        if draftRepair.odometer != nil {
            vehicle?.recordOdometerActivity()
        }
        
        try? context.save()
    }
}

extension RepairCategory {
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
