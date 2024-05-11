//
//  ServiceRecord+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import Foundation

extension ServiceRecord {
    
    var date: Date {
        get { date_ ?? Date() }
        set { date_ = newValue }
    }
    
    var odometer: Int {
        get { Int(odometer_) }
        set { odometer_ = Int64(newValue) }
    }
    
    var cost: Double? {
        get { cost_ }
        set { cost_ = newValue ?? 0}
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
    
    func updateAndSave(vehicle: Vehicle, service: Service, draftServiceRecord: DraftServiceRecord) {
        let context = DataController.shared.container.viewContext
        
        self.date = draftServiceRecord.date
        self.odometer = draftServiceRecord.odometer ?? 0
        self.cost = draftServiceRecord.cost
        self.note = draftServiceRecord.note
        self.photos = NSSet(array: draftServiceRecord.photos)

        if let odometer = draftServiceRecord.odometer {
            if odometer > vehicle.odometer {
                vehicle.odometer = odometer
            }
        }
        
        // Triggers notification reschedule, if appropriate
        service.notificationScheduled = false
        
        try? context.save()
        
//        service.updateNotifications()
    }
    
    func delete() {
        let context = DataController.shared.container.viewContext
        
        context.delete(self)
        try? context.save()
    }
}
