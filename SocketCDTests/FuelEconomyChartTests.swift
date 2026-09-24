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

        let points = ChartPoint.make(from: fixture.fillups, unit: .mpg)

        #expect(points.count == 1)
        #expect(points[0].value == 10)
    }

    @Test func partialFillsAreCombinedWithTheNextFullTank() {
        let fixture = makeFillups([
            (100, 10, .fullTank),
            (150, 5, .partialFill),
            (220, 7, .fullTank)
        ])

        let points = ChartPoint.make(from: fixture.fillups, unit: .mpg)

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

        let points = ChartPoint.make(from: fixture.fillups, unit: .mpg)

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

        let points = ChartPoint.make(from: fixture.fillups, unit: .mpg)

        #expect(points.isEmpty)
    }

    @Test func aggregateUsesTotalDistanceAndVolume() {
        let fixture = makeFillups([
            (100, 10, .fullTank),
            (200, 10, .fullTank),
            (500, 20, .fullTank)
        ])
        let points = ChartPoint.make(from: fixture.fillups, unit: .mpg)

        let average = ChartPoint.aggregateFuelEconomy(
            from: points,
            unit: .mpg
        )

        #expect(average != nil)
        #expect(abs((average ?? 0) - 13.333) < 0.001)
    }

    private func makeFillups(
        _ values: [(odometer: Int, volume: Double, type: FillType)]
    ) -> FillupFixture {
        let controller = TestDataController()
        let context = controller.context
        let vehicle = Vehicle(context: context)

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
