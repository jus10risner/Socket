//
//  DraftRepair.swift
//  SocketCD
//
//  Created by Justin Risner on 4/3/24.
//

import Foundation

class DraftRepair: ObservableObject {
    var id: UUID? = nil
    
    @Published var date: Date = Date.now
    @Published var name: String = ""
    @Published var odometer: Int? = Int("")
    @Published var cost: Double? = Double("")
    @Published var note: String = ""
    @Published var photos: [Photo] = []
    
    init(repair: Repair) {
        id = repair.id
        date = repair.date
        name = repair.name
        odometer = repair.odometer
        cost = repair.cost
        note = repair.note
        photos = repair.sortedPhotosArray
    }
    
    init() {
        self.date = date
        self.name = name
        self.odometer = odometer
        self.cost = cost
        self.note = note
        self.photos = photos
    }
    
    var canBeSaved: Bool {
        if name.count > 0 && odometer != nil {
            return true
        } else {
            return false
        }
    }
}
