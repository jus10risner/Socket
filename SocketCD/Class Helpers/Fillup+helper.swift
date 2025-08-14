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
        guard let fillups = vehicle?.sortedFillupsArray,
              let currentIndex = fillups.firstIndex(of: self),
              fillups.count > 1 else {
            return 0
        }
        
        // If this is the first fill-up ever logged, return 0 (trip distance can't be calculated)
        if currentIndex == fillups.count - 1 { return 0 }
        
        // Return 0 if this fill-up is logged as a missed fill-up (no distance calculated)
        if fillType == .missedFill {
            return 0
        }
        
        let previousOdometer = fillups[currentIndex + 1].odometer
        return odometer - previousOdometer
    }
    
    // Calculates fuel economy, when appropriate (returns 0 otherwise)
    func fuelEconomy(settings: AppSettings) -> Double {
        guard let fillups = vehicle?.sortedFillupsArray,
              let currentIndex = fillups.firstIndex(of: self),
              fillups.count > 1 else {
            return 0
        }

        if currentIndex == fillups.count - 1 { return 0 } // If this is the first fill-up ever logged, return 0 (fuel economy can't be calculated)
        
        guard fillType == .fullTank else { return 0 } // If this isn't a full tank fill-up, fuel economy cannot be reliably calculated
        
        var totalVolume = self.volume
        var totalDistance = self.tripDistance
        
        for i in (currentIndex + 1)..<fillups.count {
            let previousFillup = fillups[i]

            if previousFillup.fillType == .missedFill {
                // Stop at last missed fill (reset point for calculation window)
                break
            }

            if previousFillup.fillType == .fullTank {
                // Stop at last full fill (excluding missed fills)
                break
            }

            if previousFillup.fillType == .partialFill {
                totalVolume += previousFillup.volume
                totalDistance += previousFillup.tripDistance
            }
        }
        
        guard totalDistance > 0, totalVolume > 0 else { return 0 }

        switch settings.fuelEconomyUnit {
        case .L100km:
            return (totalVolume / Double(totalDistance)) * 100
        default:
            return Double(totalDistance) / totalVolume
        }
    }
    
    // Calculates fuel economy between the current fill-up and the one before, if appropriate
//    var fuelEconomy: Double {
//        let settings = AppSettings()
//        guard let fillupsArray = vehicle?.sortedFillupsArray else { return 0 }
//        
//        if let index = fillupsArray.firstIndex(of: self) {
//            if fillupsArray.count > 1 && self.fillType != .missedFill {
//                if self != fillupsArray.last {
//                    if self.fillType != .partialFill && fillupsArray[index + 1].fillType != .partialFill {
//                        if settings.fuelEconomyUnit == .L100km {
//                            return ((self.volume) / Double(self.tripDistance)) * 100
//                        } else {
//                            return Double(self.tripDistance) / (self.volume)
//                        }
//                    } else {
//                        return 0
//                    }
//                } else {
//                    return 0
//                }
//            } else {
//                return 0
//            }
//        } else {
//            return 0
//        }
//    }
    
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
//        let context = DataController.shared.container.viewContext
        guard let context = DataController.shared.container?.viewContext else {
            print("Core Data container not available, skipping update")
            return
        }
        
        self.date = draftFillup.date
        self.odometer = draftFillup.odometer ?? 0
        self.volume = draftFillup.volume ?? 0
        self.pricePerUnit = draftFillup.fillupCostPerUnit
        self.fillType = draftFillup.fillType
        self.note = draftFillup.note
        self.photos = NSSet(array: draftFillup.photos)
        
        if let vehicle = self.vehicle, let draftOdometer = draftFillup.odometer, draftOdometer > vehicle.odometer {
            vehicle.odometer = draftOdometer
            vehicle.updateAllServiceNotifications()
        }
        
        try? context.save()
    }
    
//    func delete() {
//        let context = DataController.shared.container.viewContext
//        
//        context.delete(self)
//        try? context.save()
//    }
}
