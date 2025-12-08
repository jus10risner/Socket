//
//  Repair+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData

extension Repair {
    
    var date: Date {
        get { date_ ?? Date() }
        set { date_ = newValue }
    }
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }
    
    var odometer: Int {
        get { Int(odometer_) }
        set { odometer_ = Int64(newValue) }
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
    
    // MARK: - CRUD Methods
    
    func updateAndSave(draftRepair: DraftRepair) {
        let context = DataController.shared.container.viewContext
        
        self.date = draftRepair.date
        self.name = draftRepair.name
        self.odometer = draftRepair.odometer ?? 0
        self.cost = draftRepair.cost
        self.note = draftRepair.note
        self.photos = NSSet(array: draftRepair.photos)
        
        if let vehicle = self.vehicle, let draftOdometer = draftRepair.odometer, draftOdometer > vehicle.odometer {
            vehicle.odometer = draftOdometer
        }
        
        try? context.save()
    }
}
