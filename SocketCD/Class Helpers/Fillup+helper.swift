//
//  Fillup+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import Foundation

extension Fillup {
    
    var date: Date {
        get { date_ ?? Date() }
        set { date_ = newValue }
    }
    
    var odometer: Int {
        get { Int(odometer_) }
        set { odometer_ = Int64(newValue) }
    }
    
    var volume: Double {
        get { volume_ }
        set { volume_ = newValue}
    }
    
    var pricePerUnit: Double? {
        get { pricePerUnit_ }
        set { pricePerUnit_ = newValue ?? 0 }
    }
    
    var fillType: FillType {
        get { FillType(rawValue: fillType_ ?? "Full Tank") ?? .fullTank }
        set { fillType_ = newValue.rawValue }
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
    
    // MARK: - Computed Properties
    
    // Calculates the distance traveled between the current fill-up and the one before, if appropriate
    var tripDistance: Int {
        guard let fillupsArray = vehicle?.sortedFillupsArray else { return 0 }
        
        if let index = fillupsArray.firstIndex(of: self) {
            if fillupsArray.count > 1 && self.fillType != .missedFill {
                if self != fillupsArray.last {
                    let previousFillupOdometer = fillupsArray[index + 1].odometer
                    
                    return self.odometer - previousFillupOdometer
                } else {
                    return 0
                }
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    // Calculates fuel economy between the current fill-up and the one before, if appropriate
    var fuelEconomy: Double {
        let settings = AppSettings()
        guard let fillupsArray = vehicle?.sortedFillupsArray else { return 0 }
        
        if let index = fillupsArray.firstIndex(of: self) {
            if fillupsArray.count > 1 && self.fillType != .missedFill {
                if self != fillupsArray.last {
                    if self.fillType != .partialFill && fillupsArray[index + 1].fillType != .partialFill {
                        if settings.fuelEconomyUnit == .L100km {
                            return ((self.volume) / Double(self.tripDistance)) * 100
                        } else {
                            return Double(self.tripDistance) / (self.volume)
                        }
                    } else {
                        return 0
                    }
                } else {
                    return 0
                }
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    // Calculates the total cost of a fill-up
    var totalCost: Double? {
        if let pricePerUnit = pricePerUnit {
            return (volume) * pricePerUnit
        } else {
            return nil
        }
    }
    
    // MARK: - Methods
    
    func updateAndSave(draftFillup: DraftFillup) {
        let context = DataController.shared.container.viewContext
        
        self.date = draftFillup.date
        self.odometer = draftFillup.odometer ?? 0
        self.volume = draftFillup.volume ?? 0
        self.pricePerUnit = draftFillup.fillupCostPerUnit
        self.fillType = draftFillup.fillType
        self.note = draftFillup.note
        self.photos = NSSet(array: draftFillup.photos)
        
        if let vehicle = self.vehicle, let draftOdometer = draftFillup.odometer, draftOdometer > vehicle.odometer {
            vehicle.odometer = draftOdometer
        }
        
//        if let odometer = draftFillup.odometer {
//            if odometer > vehicle.odometer {
//                vehicle.odometer = odometer
//            }
//        }
        
        try? context.save()
    }
    
    func delete() {
        let context = DataController.shared.container.viewContext
        
        context.delete(self)
        try? context.save()
    }
        
    // Populates either the price per unit or the total cost in the edit view, based on the user selection in settings
    func populateCorrectCost(draftFillup: DraftFillup) {
        let settings = AppSettings()
        
        switch settings.fillupCostType {
        case .perUnit:
            draftFillup.cost = self.pricePerUnit ?? 0
        case .total:
            draftFillup.cost = self.totalCost ?? 0
        }
    }
}
