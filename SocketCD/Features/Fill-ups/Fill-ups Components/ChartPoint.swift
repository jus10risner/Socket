//
//  ChartPoint.swift
//  SocketCD
//

import CoreData
import Foundation

struct ChartPoint: Identifiable, Equatable, @unchecked Sendable {
    let id: NSManagedObjectID
    let date: Date
    let value: Double
    let distance: Double
    let volume: Double

    static func make(
        from fillups: [Fillup],
        unit: FuelEconomyUnits
    ) -> [ChartPoint] {
        let sortedFillups = fillups.sorted { $0.date < $1.date }
        var points: [ChartPoint] = []
        points.reserveCapacity(sortedFillups.count)

        var baselineOdometer: Int?
        var partialVolume = 0.0

        for fillup in sortedFillups {
            switch fillup.fillType {
            case .missedFill:
                baselineOdometer = nil
                partialVolume = 0

            case .partialFill:
                if baselineOdometer != nil {
                    partialVolume += fillup.volume
                }

            case .fullTank:
                defer {
                    baselineOdometer = fillup.odometer
                    partialVolume = 0
                }

                guard let baselineOdometer else { continue }

                let distance = Double(fillup.odometer - baselineOdometer)
                let volume = partialVolume + fillup.volume

                guard let value = fuelEconomy(
                    distance: distance,
                    volume: volume,
                    unit: unit
                ) else { continue }

                points.append(
                    ChartPoint(
                        id: fillup.objectID,
                        date: fillup.date,
                        value: value,
                        distance: distance,
                        volume: volume
                    )
                )
            }
        }

        return points
    }

    static func aggregateFuelEconomy<Points: Collection>(
        from points: Points,
        unit: FuelEconomyUnits
    ) -> Double? where Points.Element == ChartPoint {
        let totals = points.reduce(into: (distance: 0.0, volume: 0.0)) {
            $0.distance += $1.distance
            $0.volume += $1.volume
        }

        return fuelEconomy(
            distance: totals.distance,
            volume: totals.volume,
            unit: unit
        )
    }

    private static func fuelEconomy(
        distance: Double,
        volume: Double,
        unit: FuelEconomyUnits
    ) -> Double? {
        guard distance > 0, volume > 0 else { return nil }

        switch unit {
        case .L100km:
            return (volume / distance) * 100
        default:
            return distance / volume
        }
    }
}
