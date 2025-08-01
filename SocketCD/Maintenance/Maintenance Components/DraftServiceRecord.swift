//
//  DraftServiceRecord.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import Foundation

class DraftServiceRecord: ObservableObject {
    var id: UUID? = nil
    
    @Published var date: Date = Date.now
    @Published var odometer: Int? = nil
    @Published var cost: Double? = nil
    @Published var note: String = ""
    @Published var photos: [Photo] = []
    
    // Initializes with an optional Service Record, for use in add/edit context
    init(record: ServiceRecord? = nil) {
        if let record {
            id = record.id
            date = record.date
            odometer = record.odometer
            cost = record.cost
            note = record.note
            photos = record.sortedPhotosArray
        }
    }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        odometer != nil
    }
}
