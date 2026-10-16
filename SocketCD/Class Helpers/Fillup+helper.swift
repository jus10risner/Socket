//
//  Fillup+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import Foundation

extension Fillup {
    var distanceUnit: DistanceUnits {
        vehicle?.distanceUnit ?? AppSettingsStore.shared.distanceUnit
    }

    var volumeUnit: VolumeUnits {
        vehicle?.volumeUnit ?? AppSettingsStore.shared.volumeUnit
    }

    var fuelEconomyUnit: FuelEconomyUnits {
        vehicle?.fuelEconomyUnit ?? AppSettingsStore.shared.fuelEconomyUnit
    }

    var chartDataRevision: Int {
        var hasher = Hasher()
        hasher.combine(date_)
        hasher.combine(odometer_)
        hasher.combine(volume_)
        hasher.combine(fillType_)
        return hasher.finalize()
    }

    
    var date: Date {
        get { date_ ?? Date() }
        set { date_ = newValue }
    }
    
    var odometer: Int {
        get { displayedDistance(storedOdometer) }
        set { storedOdometer = canonicalDistance(newValue) }
    }

    private var storedOdometer: Int64 {
        get { odometer_ }
        set { odometer_ = newValue }
    }
    
    var volume: Double {
        get {
            guard vehicle?.usesCanonicalMeasurements == true else { return storedVolume }
            return MeasurementConverter.volume(fromLiters: storedVolume, unit: vehicle?.volumeUnit ?? .liters)
        }
        set {
            storedVolume = vehicle?.usesCanonicalMeasurements == true
                ? MeasurementConverter.liters(from: newValue, unit: vehicle?.volumeUnit ?? .liters)
                : newValue
        }
    }

    private var storedVolume: Double {
        get { volume_ }
        set { volume_ = newValue }
    }

    var pricePerUnit: Double? {
        get {
            guard vehicle?.usesCanonicalMeasurements == true else { return pricePerUnit_ }
            return MeasurementConverter.pricePerDisplayedUnit(
                fromPricePerLiter: pricePerUnit_,
                unit: vehicle?.volumeUnit ?? .liters
            )
        }
        set {
            let price = newValue ?? 0
            pricePerUnit_ = vehicle?.usesCanonicalMeasurements == true
                ? MeasurementConverter.pricePerLiter(from: price, unit: vehicle?.volumeUnit ?? .liters)
                : price
        }
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

    var sortedDocumentsArray: [AttachedDocument] {
        let set = documents as? Set<AttachedDocument> ?? []
        return set.sorted { $0.timeStamp < $1.timeStamp }
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
        
        let previousOdometer = fillups[currentIndex + 1].storedOdometer
        return displayedDistance(storedOdometer - previousOdometer)
    }
    
    // Finds the nearest previous fill-up that establishes a fuel-economy baseline.
    func previousFuelEconomyBaseline(in fillups: [Fillup]) -> Fillup? {
        guard let currentIndex = fillups.firstIndex(of: self) else { return nil }

        for i in (currentIndex + 1)..<fillups.count {
            let candidate = fillups[i]

            if candidate.fillType == .fullTank || candidate.fillType == .missedFill {
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

        // A missed fill cannot produce its own result, but its odometer starts a new baseline.
        guard let previousBaseline = previousFuelEconomyBaseline(in: fillups) else { return 0 }
        
        var totalVolume = volumeLiters
        var totalDistance = tripDistanceKilometers
        
        // Add any partials between this full tank and the previous full tank
        if let currentIndex = fillups.firstIndex(of: self),
           let prevIndex = fillups.firstIndex(of: previousBaseline) {
            for i in (currentIndex + 1)..<prevIndex {
                let prev = fillups[i]
                if prev.fillType == .partialFill {
                    totalVolume += prev.volumeLiters
                    totalDistance += prev.tripDistanceKilometers
                }
            }
        }
        
        guard totalDistance > 0, totalVolume > 0 else { return 0 }

        return MeasurementConverter.fuelEconomy(
            distanceKilometers: totalDistance,
            volumeLiters: totalVolume,
            unit: fuelEconomyUnit
        )
    }

    var volumeLiters: Double {
        guard let vehicle, !vehicle.usesCanonicalMeasurements else { return storedVolume }
        return MeasurementConverter.liters(from: storedVolume, unit: vehicle.volumeUnit)
    }

    var odometerKilometers: Double {
        guard let vehicle, !vehicle.usesCanonicalMeasurements else { return Double(storedOdometer) }
        return MeasurementConverter.kilometers(from: Double(storedOdometer), unit: vehicle.distanceUnit)
    }

    private var tripDistanceKilometers: Double {
        guard let fillups = vehicle?.sortedFillupsArray,
              let currentIndex = fillups.firstIndex(of: self),
              currentIndex < fillups.count - 1,
              fillType != .missedFill else { return 0 }
        return odometerKilometers - fillups[currentIndex + 1].odometerKilometers
    }

    private func displayedDistance(_ value: Int64) -> Int {
        vehicle?.displayedDistance(fromStored: value) ?? Int(value)
    }

    private func canonicalDistance(_ value: Int) -> Int64 {
        vehicle?.storedDistance(fromDisplayed: value) ?? Int64(value)
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
        self.documents = NSSet(array: draftFillup.documents)
        
        if let vehicle = self.vehicle, let draftOdometer = draftFillup.odometer, draftOdometer > vehicle.odometer {
            vehicle.odometer = draftOdometer
        }
        if draftFillup.odometer != nil {
            vehicle?.recordOdometerActivity()
        }
        
        try? context.save()
    }
}
