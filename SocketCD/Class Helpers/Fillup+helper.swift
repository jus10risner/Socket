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
    
    // Finds the nearest previous full tank fill-up (ignoring partial fills, but stopping at missed fills).
    func previousFullTank(in fillups: [Fillup]) -> Fillup? {
        guard let currentIndex = fillups.firstIndex(of: self) else { return nil }

        for i in (currentIndex + 1)..<fillups.count {
            let candidate = fillups[i]

            if candidate.fillType == .missedFill {
                // Reset point — fuel economy cannot be calculated across a missed fill
                break
            }

            if candidate.fillType == .fullTank {
                return candidate
            }
        }

        return nil
    }
    
    // Calculates fuel economy, when appropriate (returns 0 otherwise)
    func fuelEconomy() -> Double {
        guard let fillups = vehicle?.sortedFillupsArray,
              fillups.count > 1,
              fillType == .fullTank else {
            return 0
        }

        // Find baseline: nearest previous full tank
        guard let previousFullTank = previousFullTank(in: fillups) else { return 0 }
        
        var totalVolume = self.volume
        var totalDistance = self.tripDistance
        
        // Add any partials between this full tank and the previous full tank
        if let currentIndex = fillups.firstIndex(of: self),
           let prevIndex = fillups.firstIndex(of: previousFullTank) {
            for i in (currentIndex + 1)..<prevIndex {
                let prev = fillups[i]
                if prev.fillType == .partialFill {
                    totalVolume += prev.volume
                    totalDistance += prev.tripDistance
                }
            }
        }
        
        guard totalDistance > 0, totalVolume > 0 else { return 0 }

        switch AppSettings.shared.fuelEconomyUnit {
        case .L100km:
            return (totalVolume / Double(totalDistance)) * 100
        default:
            return Double(totalDistance) / totalVolume
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
        
        try? context.save()
    }
}
