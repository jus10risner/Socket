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
    @Published var odometer: Int? = Int("")
    @Published var cost: Double? = Double("")
    @Published var note: String = ""
    @Published var photos: [Photo] = []
    
    // Used when editing an existing service record
    init(record: ServiceRecord) {
        id = record.id
        date = record.date
        odometer = record.odometer
        cost = record.cost
        note = record.note
        photos = record.sortedPhotosArray
    }
    
    // Used when adding a new service record
    init() { }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        odometer != nil
    }
}
