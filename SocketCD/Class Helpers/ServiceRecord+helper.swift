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
    
    func updateAndSave(service: Service, draftServiceRecord: DraftServiceRecord) {
        let context = DataController.shared.container.viewContext
        
        self.date = draftServiceRecord.date
        self.odometer = draftServiceRecord.odometer ?? 0
        self.cost = draftServiceRecord.cost
        self.note = draftServiceRecord.note
        self.photos = NSSet(array: draftServiceRecord.photos)
        
        if let vehicle = service.vehicle, let draftOdometer = draftServiceRecord.odometer, draftOdometer > vehicle.odometer {
            vehicle.odometer = draftOdometer
            service.updateNotifications(vehicle: vehicle)
        }

//        if let odometer = draftServiceRecord.odometer {
//            if odometer > vehicle.odometer {
//                vehicle.odometer = odometer
//            }
//        }
        
//        if let vehicle = service.vehicle {
//            service.updateNotifications(vehicle: vehicle)
//        }
        
        try? context.save()
    }
    
//    func delete(for service: Service) {
//        let context = DataController.shared.container.viewContext
//        
//        service.cancelPendingNotifications()
//        context.delete(self)
//        try? context.save()
//    }
}
