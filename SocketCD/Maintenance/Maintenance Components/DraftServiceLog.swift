//
//  DraftServiceLog.swift
//  SocketCD
//
//  Created by Justin Risner on 9/8/25.
//

import Foundation

class DraftServiceLog: ObservableObject {
    var id: UUID? = nil
    
    @Published var date: Date = Date.now
    @Published var odometer: Int? = nil
    @Published var cost: Double? = nil
    @Published var note: String = ""
    @Published var photos: [Photo] = []
    @Published var selectedServiceIDs: Set<UUID> = []
    
    
    // Initializes with an optional Service Record, for use in add/edit context
    init(record: ServiceRecord? = nil, preselectedService: Service? = nil) {
        if let service = preselectedService, let id = service.id {
            self.selectedServiceIDs = [id]   // preselect if passed in
        }
        
        if let record {
            if  let log = record.serviceLog {
                id = log.id
                date = log.date
                odometer = log.odometer
                cost = log.cost
                note = log.note
                photos = log.sortedPhotosArray
                selectedServiceIDs = Set(log.sortedServicesArray.compactMap { $0.id })
            } else {
                id = UUID()
                date = record.date
                odometer = record.odometer
                cost = record.cost
                note = record.note
                photos = record.sortedPhotosArray
                if let serviceID = record.service?.id { selectedServiceIDs = [serviceID] }
            }
        }
    }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        odometer != nil && !selectedServiceIDs.isEmpty
    }
    
    // Returns the names of all selected services as a String
    func selectedServiceNames(from vehicle: Vehicle) -> String {
        vehicle.sortedServicesArray
            .filter { service in
                if let id = service.id {
                    return selectedServiceIDs.contains(id)
                } else {
                    return false
                }
            }
            .compactMap { $0.name }
            .joined(separator: ", ")
    }
}
