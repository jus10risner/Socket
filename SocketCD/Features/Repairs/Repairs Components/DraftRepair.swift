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
    @Published var odometer: Int? = nil
    @Published var cost: Double? = nil
    @Published var note: String = ""
    @Published var photos: [Photo] = []
    
    // Initializes with an optional Repair, for use in add/edit context
    init(repair: Repair? = nil) {
        if let repair {
            id = repair.id
            date = repair.date
            name = repair.name
            odometer = repair.odometer
            cost = repair.cost
            note = repair.note
            photos = repair.sortedPhotosArray
        }
    }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        !name.isBlank && odometer.hasValue
    }
}
