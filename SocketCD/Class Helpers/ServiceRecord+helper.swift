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
    
    // MARK: - Effective values (prefers serviceLog values, but falls back to serviceRecord values for older entries)
    var effectiveDate: Date {
        serviceLog?.date ?? date
    }
    
    var effectiveOdometer: Int {
        serviceLog?.odometer ?? odometer
    }
    
    var effectiveCost: Double? {
        serviceLog?.cost ?? cost
    }
    
    var effectiveNote: String {
        serviceLog?.note ?? note
    }
    
    var effectivePhotos: [Photo] {
        if let log = serviceLog {
            return log.sortedPhotosArray
        } else {
            return sortedPhotosArray
        }
    }
    
    // MARK: - CRUD Methods
    
    func updateAndSave(service: Service, draftServiceLog: DraftServiceLog) {
        let context = DataController.shared.container.viewContext
        
        self.date = draftServiceLog.date
        self.odometer = draftServiceLog.odometer ?? 0
        self.cost = draftServiceLog.cost
        self.note = draftServiceLog.note
        self.photos = NSSet(array: draftServiceLog.photos)

        if let vehicle = service.vehicle, let draftOdometer = draftServiceLog.odometer, draftOdometer > vehicle.odometer {
            vehicle.odometer = draftOdometer
            service.updateNotifications(vehicle: vehicle)
        }
        
        try? context.save()
    }
}
