//
//  OdometerValidator.swift
//  SocketCD
//

import Foundation

enum OdometerValidationContext {
    case currentVehicle
    case historicalRecord
}

enum OdometerWarning: Hashable, Identifiable {
    case lowerThanCurrent
    case unusuallyHigh

    var id: Self { self }

    func message(
        entered: Int,
        current: Int,
        distanceUnit: String
    ) -> LocalizedStringResource {
        switch self {
        case .lowerThanCurrent:
            "You entered \(entered.formatted()) \(distanceUnit), which is lower than the current odometer value of \(current.formatted()) \(distanceUnit)."
        case .unusuallyHigh:
            "You entered \(entered.formatted()) \(distanceUnit), which is much higher than the current odometer value of \(current.formatted()) \(distanceUnit)."
        }
    }
}

enum OdometerValidator {
    static func warning(
        entered: Int,
        current: Int,
        context: OdometerValidationContext
    ) -> OdometerWarning? {
        guard current > 0 else { return nil }

        if context == .currentVehicle, entered < current {
            return .lowerThanCurrent
        }

        if current <= Int.max / 10, entered >= current * 10 {
            return .unusuallyHigh
        }

        return nil
    }
}
