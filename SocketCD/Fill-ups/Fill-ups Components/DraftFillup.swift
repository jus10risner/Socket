//
//  DraftFillup.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import Foundation

class DraftFillup: ObservableObject {
    private let settings: AppSettings
    var id: UUID? = nil
    
    @Published var date: Date = Date.now
    @Published var odometer: Int? = Int("")
    @Published var volume: Double? = Double("")
    @Published var cost: Double? = Double("")
    @Published var fillType: FillType = .fullTank
    @Published var note: String = ""
    @Published var photos: [Photo] = []
    
    // Used when editing an existin fill-up record
    init(fillup: Fillup, settings: AppSettings = AppSettings()) {
        self.settings = settings
        
        id = fillup.id
        date = fillup.date
        odometer = fillup.odometer
        volume = fillup.volume
        fillType = fillup.fillType
        note = fillup.note
        photos = fillup.sortedPhotosArray
        
        switch settings.fillupCostType {
        case .perUnit:
            cost = fillup.pricePerUnit ?? 0
        case .total:
            cost = fillup.totalCost ?? 0
        }
    }
    
    // Used when adding a new fill-up
    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
    }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        odometer != nil && volume != nil
    }
    
    // Returns either the price per volume unit, or the total cost of the fill-up, based on the user's selection in Settings
    var fillupCostPerUnit: Double {
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
