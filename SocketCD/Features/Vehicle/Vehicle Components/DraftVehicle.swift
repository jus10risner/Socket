//
//  DraftVehicle.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import SwiftUI

class DraftVehicle: ObservableObject {
    var id: UUID? = nil
    
    @Published var name: String = ""
    @Published var odometer: Int? = nil
    @Published var selectedColor: Color = Color(.socketPurple)
    @Published var photo: Photo?
    @Published var distanceUnit: DistanceUnits
    @Published var volumeUnit: VolumeUnits
    @Published var fuelEconomyUnit: FuelEconomyUnits
    @Published var legacyDistanceUnit: DistanceUnits
    @Published var legacyVolumeUnit: VolumeUnits

    let usesCanonicalMeasurements: Bool

    private let originalDistanceUnit: DistanceUnits
    private let originalVolumeUnit: VolumeUnits
    private let originalFuelEconomyUnit: FuelEconomyUnits
    private let originalLegacyDistanceUnit: DistanceUnits
    private let originalLegacyVolumeUnit: VolumeUnits
    
    // Initializes with an optional Vehicle, for use in add/edit context
    init(vehicle: Vehicle? = nil) {
        let settings = AppSettingsStore.shared

        if let vehicle {
            id = vehicle.id
            name = vehicle.name
            odometer = vehicle.odometer
            selectedColor = vehicle.backgroundColor
            photo = vehicle.photo
            distanceUnit = vehicle.distanceUnit
            volumeUnit = vehicle.volumeUnit
            fuelEconomyUnit = vehicle.fuelEconomyUnit
            legacyDistanceUnit = vehicle.distanceUnit
            legacyVolumeUnit = vehicle.volumeUnit
            usesCanonicalMeasurements = vehicle.usesCanonicalMeasurements
            originalDistanceUnit = vehicle.distanceUnit
            originalVolumeUnit = vehicle.volumeUnit
            originalFuelEconomyUnit = vehicle.fuelEconomyUnit
            originalLegacyDistanceUnit = vehicle.distanceUnit
            originalLegacyVolumeUnit = vehicle.volumeUnit
        } else {
            distanceUnit = settings.distanceUnit
            volumeUnit = settings.volumeUnit
            fuelEconomyUnit = settings.fuelEconomyUnit
            legacyDistanceUnit = settings.distanceUnit
            legacyVolumeUnit = settings.volumeUnit
            usesCanonicalMeasurements = true
            originalDistanceUnit = settings.distanceUnit
            originalVolumeUnit = settings.volumeUnit
            originalFuelEconomyUnit = settings.fuelEconomyUnit
            originalLegacyDistanceUnit = settings.distanceUnit
            originalLegacyVolumeUnit = settings.volumeUnit
        }
    }

    var shouldMigrateMeasurements: Bool {
        !usesCanonicalMeasurements && (
            distanceUnit != originalDistanceUnit ||
            volumeUnit != originalVolumeUnit ||
            fuelEconomyUnit != originalFuelEconomyUnit ||
            legacyDistanceUnit != originalLegacyDistanceUnit ||
            legacyVolumeUnit != originalLegacyVolumeUnit
        )
    }

    func setDistanceUnit(_ newValue: DistanceUnits) {
        if let odometer, newValue != distanceUnit {
            let kilometers = MeasurementConverter.kilometers(from: Double(odometer), unit: distanceUnit)
            self.odometer = Int(MeasurementConverter.distance(
                fromKilometers: kilometers,
                unit: newValue
            ).rounded())
        }
        distanceUnit = newValue
    }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        !name.isBlank && odometer.hasValue
    }
}
