//
//  FuelEconomyChartTests.swift
//  SocketCDTests
//

import CoreData
import Testing
@testable import SocketCD

@Suite("Fuel Economy Chart Tests")
struct FuelEconomyChartTests {
    @Test func consecutiveFullTanksProduceOnePoint() {
        let fixture = makeFillups([
            (100, 10, .fullTank),
            (200, 10, .fullTank)
        ])

        let points = ChartPoint.make(from: fixture.fillups, unit: .kmL)

        #expect(points.count == 1)
        #expect(points[0].value == 10)
    }

    @Test func partialFillsAreCombinedWithTheNextFullTank() {
        let fixture = makeFillups([
            (100, 10, .fullTank),
            (150, 5, .partialFill),
            (220, 7, .fullTank)
        ])

        let points = ChartPoint.make(from: fixture.fillups, unit: .kmL)

        #expect(points.count == 1)
        #expect(points[0].value == 10)
    }

    @Test func missedFillStartsANewBaselineForTheNextFullTank() {
        let fixture = makeFillups([
            (100, 10, .fullTank),
            (150, 5, .missedFill),
            (200, 10, .fullTank),
            (300, 10, .fullTank)
        ])

        let points = ChartPoint.make(from: fixture.fillups, unit: .kmL)

        #expect(points.count == 2)
        #expect(points[0].value == 5)
        #expect(points[1].value == 10)
    }

    @Test func litersPerHundredKilometersUsesInverseFormula() {
        let fixture = makeFillups([
            (100, 10, .fullTank),
            (300, 16, .fullTank)
        ])

        let points = ChartPoint.make(from: fixture.fillups, unit: .L100km)

        #expect(points.count == 1)
        #expect(points[0].value == 8)
    }

    @Test func invalidVolumeDoesNotProduceAChartPoint() {
        let fixture = makeFillups([
            (100, 10, .fullTank),
            (200, 0, .fullTank)
        ])

        let points = ChartPoint.make(from: fixture.fillups, unit: .kmL)

        #expect(points.isEmpty)
    }

    @Test func aggregateUsesTotalDistanceAndVolume() {
        let fixture = makeFillups([
            (100, 10, .fullTank),
            (200, 10, .fullTank),
            (500, 20, .fullTank)
        ])
        let points = ChartPoint.make(from: fixture.fillups, unit: .kmL)

        let average = ChartPoint.aggregateFuelEconomy(
            from: points,
            unit: .kmL
        )

        #expect(average != nil)
        #expect(abs((average ?? 0) - 13.333) < 0.001)
    }

    @Test func imperialMPGUsesImperialGallons() {
        let value = MeasurementConverter.fuelEconomy(
            distanceKilometers: 100,
            volumeLiters: 10,
            unit: .mpgImperial
        )

        #expect(abs(value - 28.248) < 0.001)
    }

    @Test func volumeAndPriceConversionPreservesTotalCost() {
        let gallons = 10.0
        let pricePerGallon = 3.50
        let liters = MeasurementConverter.liters(from: gallons, unit: .usGallons)
        let pricePerLiter = MeasurementConverter.pricePerLiter(from: pricePerGallon, unit: .usGallons)

        #expect(abs(liters * pricePerLiter - gallons * pricePerGallon) < 0.000_001)
    }

    @Test func allFuelEconomyConversionsUseCanonicalMeasurements() {
        let distance = 160.9344
        let volume = 37.85411784

        #expect(abs(MeasurementConverter.fuelEconomy(distanceKilometers: distance, volumeLiters: volume, unit: .mpg) - 10) < 0.000_001)
        #expect(abs(MeasurementConverter.fuelEconomy(distanceKilometers: distance, volumeLiters: volume, unit: .mpgImperial) - 12.009_49) < 0.000_01)
        #expect(abs(MeasurementConverter.fuelEconomy(distanceKilometers: distance, volumeLiters: volume, unit: .kmL) - 4.251_44) < 0.000_01)
        #expect(abs(MeasurementConverter.fuelEconomy(distanceKilometers: distance, volumeLiters: volume, unit: .L100km) - 23.521_46) < 0.000_01)
        #expect(abs(MeasurementConverter.fuelEconomy(distanceKilometers: distance, volumeLiters: volume, unit: .kmGal) - 16.093_44) < 0.000_01)
    }

    @Test func distanceAndVolumeConversionsRoundTrip() {
        for unit in DistanceUnits.allCases {
            let displayed = MeasurementConverter.distance(fromKilometers: 12_345.678, unit: unit)
            let restored = MeasurementConverter.kilometers(from: displayed, unit: unit)
            #expect(abs(restored - 12_345.678) < 0.000_001)
        }

        for unit in VolumeUnits.allCases {
            let displayed = MeasurementConverter.volume(fromLiters: 45.678, unit: unit)
            let restored = MeasurementConverter.liters(from: displayed, unit: unit)
            #expect(abs(restored - 45.678) < 0.000_001)
        }
    }

    @Test func editingCanonicalVehicleWithoutChangingOdometerPreservesStoredValue() {
        let controller = TestDataController()
        let context = controller.context
        let vehicle = Vehicle(context: context)
        vehicle.distanceUnit = .kilometers
        vehicle.volumeUnit = .liters
        vehicle.fuelEconomyUnit = .L100km
        vehicle.markMeasurementsAsCanonical()
        vehicle.odometer = 102

        let draft = DraftVehicle(vehicle: vehicle)
        draft.name = "Updated Name"
        vehicle.updateAndSave(draftVehicle: draft)

        #expect(vehicle.odometer == 102)

        let milesDraft = DraftVehicle(vehicle: vehicle)
        milesDraft.setDistanceUnit(.miles)
        vehicle.updateAndSave(draftVehicle: milesDraft)

        #expect(vehicle.distanceUnit == .miles)

        vehicle.distanceUnit = .kilometers
        #expect(vehicle.odometer == 102)
    }

    @Test func legacyUSMeasurementsAreNormalizedForCalculations() {
        let controller = TestDataController()
        let context = controller.context
        let vehicle = Vehicle(context: context)
        vehicle.distanceUnit = .miles
        vehicle.volumeUnit = .usGallons
        vehicle.fuelEconomyUnit = .mpg

        let first = Fillup(context: context)
        first.vehicle = vehicle
        first.date = Date(timeIntervalSince1970: 0)
        first.odometer = 100
        first.volume = 10
        first.fillType = .fullTank

        let second = Fillup(context: context)
        second.vehicle = vehicle
        second.date = Date(timeIntervalSince1970: 1)
        second.odometer = 200
        second.volume = 10
        second.fillType = .fullTank

        let points = ChartPoint.make(from: [first, second], unit: .mpg)

        #expect(points.count == 1)
        #expect(abs(points[0].value - 10) < 0.000_001)
    }

    @Test func changingALegacyVehicleToUKMigratesOnlyThatVehicle() {
        let controller = TestDataController()
        let context = controller.context
        let vehicle = Vehicle(context: context)
        vehicle.name = "Legacy Car"
        vehicle.distanceUnit = .miles
        vehicle.volumeUnit = .usGallons
        vehicle.fuelEconomyUnit = .mpg
        vehicle.odometer = 200

        let untouchedVehicle = Vehicle(context: context)
        untouchedVehicle.distanceUnit = .miles
        untouchedVehicle.volumeUnit = .usGallons
        untouchedVehicle.fuelEconomyUnit = .mpg
        untouchedVehicle.odometer = 500

        let fillup = Fillup(context: context)
        fillup.vehicle = vehicle
        fillup.odometer = 200
        fillup.volume = 10
        fillup.pricePerUnit = 3.50

        let draft = DraftVehicle(vehicle: vehicle)
        draft.volumeUnit = .liters
        draft.fuelEconomyUnit = .mpgImperial
        vehicle.updateAndSave(draftVehicle: draft)

        #expect(vehicle.usesCanonicalMeasurements)
        #expect(vehicle.distanceUnit == .miles)
        #expect(vehicle.volumeUnit == .liters)
        #expect(vehicle.fuelEconomyUnit == .mpgImperial)
        #expect(vehicle.odometer == 200)
        #expect(abs(fillup.volume - 37.854_117_84) < 0.000_001)
        #expect(abs((fillup.totalCost ?? 0) - 35) < 0.000_001)
        #expect(!untouchedVehicle.usesCanonicalMeasurements)
        #expect(untouchedVehicle.odometer == 500)
    }

    @Test func confirmedLegacyLitersAreNotTreatedAsGallons() {
        let controller = TestDataController()
        let context = controller.context
        let vehicle = Vehicle(context: context)
        vehicle.name = "UK Car"
        vehicle.distanceUnit = .miles
        vehicle.volumeUnit = .usGallons
        vehicle.fuelEconomyUnit = .mpg
        vehicle.odometer = 200

        let fillup = Fillup(context: context)
        fillup.vehicle = vehicle
        fillup.odometer = 200
        fillup.volume = 10

        let draft = DraftVehicle(vehicle: vehicle)
        draft.volumeUnit = .liters
        draft.fuelEconomyUnit = .mpgImperial
        draft.legacyVolumeUnit = .liters
        vehicle.updateAndSave(draftVehicle: draft)

        #expect(vehicle.usesCanonicalMeasurements)
        #expect(abs(fillup.volume - 10) < 0.000_001)
    }

    private func makeFillups(
        _ values: [(odometer: Int, volume: Double, type: FillType)]
    ) -> FillupFixture {
        let controller = TestDataController()
        let context = controller.context
        let vehicle = Vehicle(context: context)
        vehicle.distanceUnit = .kilometers
        vehicle.volumeUnit = .liters
        vehicle.fuelEconomyUnit = .kmL
        vehicle.markMeasurementsAsCanonical()

        let fillups = values.enumerated().map { index, value in
            let fillup = Fillup(context: context)
            fillup.vehicle = vehicle
            fillup.date = Date(timeIntervalSince1970: Double(index))
            fillup.odometer = value.odometer
            fillup.volume = value.volume
            fillup.fillType = value.type
            return fillup
        }

        return FillupFixture(controller: controller, fillups: fillups)
    }
}

private struct FillupFixture {
    // Retains the in-memory Core Data stack while its managed objects are in use.
    let controller: TestDataController
    let fillups: [Fillup]
}
