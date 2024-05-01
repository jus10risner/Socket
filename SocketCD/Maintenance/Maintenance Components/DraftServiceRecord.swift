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
    
    init(record: ServiceRecord) {
        id = record.id
        date = record.date
        odometer = record.odometer
        cost = record.cost
        note = record.note
        photos = record.sortedPhotosArray
    }
    
    init() {
        self.date = date
        self.odometer = odometer
        self.cost = cost
        self.note = note
        self.photos = photos
    }
    
    var canBeSaved: Bool {
        if odometer != nil {
            return true
        } else {
            return false
        }
    }
}
