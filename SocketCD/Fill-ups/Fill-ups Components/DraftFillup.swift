//
//  DraftFillup.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import Foundation

class DraftFillup: ObservableObject {
    var id: UUID? = nil
    
    @Published var date: Date = Date.now
    @Published var odometer: Int? = Int("")
    @Published var volume: Double? = Double("")
    @Published var cost: Double? = Double("")
    @Published var fillType: FillType = .fullTank
    @Published var note: String = ""
    @Published var photos: [Photo] = []
    
    init(fillup: Fillup) {
        id = fillup.id
        date = fillup.date
        odometer = fillup.odometer
        volume = fillup.volume
        cost = fillup.pricePerUnit
        fillType = fillup.fillType
        note = fillup.note
        photos = fillup.sortedPhotosArray
    }
    
    init() {
        self.date = date
        self.odometer = odometer
        self.volume = volume
        self.cost = cost
        self.fillType = fillType
        self.note = note
        self.photos = photos
    }
    
    var canBeSaved: Bool {
        if odometer != nil && volume != nil {
            return true
        } else {
            return false
        }
    }
    
    var fillupCostPerUnit: Double {
        let settings = AppSettings()
        
        guard let volume = self.volume else { return 0 }
        guard let cost = self.cost else { return 0 }
        
        switch settings.fillupCostType {
        case .perUnit:
            return cost
        case .total:
            return cost / volume
        }
    }
}
