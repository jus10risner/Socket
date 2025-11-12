//
//  ServiceLog+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 9/8/25.
//

import Foundation

extension ServiceLog {
    
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
    
    var sortedServicesArray: [Service] {
        let recordsSet = records as? Set<ServiceRecord> ?? []
        
        return recordsSet.compactMap { $0.service }.sorted { $0.name < $1.name }
    }
    
    // MARK: - CRUD Methods
    
    func updateAndSave(draftServiceLog: DraftServiceLog, allServices: [Service]) {
        let context = DataController.shared.container.viewContext

        // Update the log
        self.date = draftServiceLog.date
        self.odometer = draftServiceLog.odometer ?? 0
        self.cost = draftServiceLog.cost
        self.note = draftServiceLog.note
        self.photos = NSSet(array: draftServiceLog.photos)

        let existingRecords = (records as? Set<ServiceRecord>) ?? []

        // Sync records with selected services
        var existingByService: [Service: ServiceRecord] = [:]
        for record in existingRecords {
            if let svc = record.service {
                existingByService[svc] = record
            }
        }

        // Update existing or add new
        let selectedServices = draftServiceLog.selectedServiceIDs.compactMap { id in
            allServices.first(where: { $0.id == id })
        }
        
        for service in selectedServices {
            if let record = existingByService[service] {
                record.date = draftServiceLog.date
                record.odometer = draftServiceLog.odometer ?? 0
            } else {
                let newRecord = ServiceRecord(context: context)
                newRecord.id = UUID()
                newRecord.service = service
                newRecord.serviceLog = self
                newRecord.date = draftServiceLog.date
                newRecord.odometer = draftServiceLog.odometer ?? 0
            }
        }

        // Remove deselected
        for (service, record) in existingByService {
            if !selectedServices.contains(service) {
                context.delete(record)
            }
        }

        // Update vehicle odometer if needed
        for service in selectedServices {
            if let vehicle = service.vehicle,
               let draftOdometer = draftServiceLog.odometer,
               draftOdometer > vehicle.odometer {
                vehicle.odometer = draftOdometer
//                service.updateNotifications(vehicle: vehicle)
            }
                }

        try? context.save()
    }
}
