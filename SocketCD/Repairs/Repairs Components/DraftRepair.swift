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
    
    // Used when editing an existing repair record
    init(repair: Repair) {
        id = repair.id
        date = repair.date
        name = repair.name
        odometer = repair.odometer
        cost = repair.cost
        note = repair.note
        photos = repair.sortedPhotosArray
    }
    
    // Used when creating a new repair record
    init() { }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        name.count > 0 && odometer != nil
    }
}
