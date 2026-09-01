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
        let values = makeFillups([
            (100, 10, .fullTank),
            (200, 10, .fullTank)
        ])

        let points = ChartPoint.make(from: values, unit: .mpg)

        #expect(points.count == 1)
        #expect(points[0].value == 10)
    }

    @Test func partialFillsAreCombinedWithTheNextFullTank() {
        let values = makeFillups([
            (100, 10, .fullTank),
            (150, 5, .partialFill),
            (220, 7, .fullTank)
        ])

        let points = ChartPoint.make(from: values, unit: .mpg)

        #expect(points.count == 1)
        #expect(points[0].value == 10)
    }

    @Test func missedFillResetsTheFullTankBaseline() {
        let values = makeFillups([
            (100, 10, .fullTank),
            (150, 5, .missedFill),
            (200, 10, .fullTank),
            (300, 10, .fullTank)
        ])

        let points = ChartPoint.make(from: values, unit: .mpg)

        #expect(points.count == 1)
        #expect(points[0].value == 10)
    }

    @Test func litersPerHundredKilometersUsesInverseFormula() {
        let values = makeFillups([
            (100, 10, .fullTank),
            (300, 16, .fullTank)
        ])

        let points = ChartPoint.make(from: values, unit: .L100km)

        #expect(points.count == 1)
        #expect(points[0].value == 8)
    }

    @Test func invalidVolumeDoesNotProduceAChartPoint() {
        let values = makeFillups([
            (100, 10, .fullTank),
            (200, 0, .fullTank)
        ])

        let points = ChartPoint.make(from: values, unit: .mpg)

        #expect(points.isEmpty)
    }

    @Test func aggregateUsesTotalDistanceAndVolume() {
        let values = makeFillups([
            (100, 10, .fullTank),
            (200, 10, .fullTank),
            (500, 20, .fullTank)
        ])
        let points = ChartPoint.make(from: values, unit: .mpg)

        let average = ChartPoint.aggregateFuelEconomy(
            from: points,
            unit: .mpg
        )

        #expect(average != nil)
        #expect(abs((average ?? 0) - 13.333) < 0.001)
    }

    private func makeFillups(
        _ values: [(odometer: Int, volume: Double, type: FillType)]
    ) -> [Fillup] {
        let controller = TestDataController()
        let context = controller.context
        let vehicle = Vehicle(context: context)

        return values.enumerated().map { index, value in
            let fillup = Fillup(context: context)
            fillup.vehicle = vehicle
            fillup.date = Date(timeIntervalSince1970: Double(index))
            fillup.odometer = value.odometer
            fillup.volume = value.volume
            fillup.fillType = value.type
            return fillup
        }
    }
}
