//
//  OdometerValidatorTests.swift
//  SocketCDTests
//

import Testing
@testable import SocketCD

struct OdometerValidatorTests {
    @Test func currentVehicleWarnsForLowerReading() {
        #expect(
            OdometerValidator.warning(
                entered: 49_999,
                current: 50_000,
                context: .currentVehicle
            ) == .lowerThanCurrent
        )
    }

    @Test func historicalRecordAllowsLowerReading() {
        #expect(
            OdometerValidator.warning(
                entered: 25_000,
                current: 50_000,
                context: .historicalRecord
            ) == nil
        )
    }

    @Test func warnsAtTenTimesCurrentReading() {
        #expect(
            OdometerValidator.warning(
                entered: 500_000,
                current: 50_000,
                context: .historicalRecord
            ) == .unusuallyHigh
        )
    }

    @Test func allowsReadingBelowTenTimesCurrent() {
        #expect(
            OdometerValidator.warning(
                entered: 499_999,
                current: 50_000,
                context: .currentVehicle
            ) == nil
        )
    }

    @Test func skipsValidationForZeroCurrentReading() {
        #expect(
            OdometerValidator.warning(
                entered: 1_000_000,
                current: 0,
                context: .currentVehicle
            ) == nil
        )
    }

    @Test func avoidsOverflowNearIntegerLimit() {
        #expect(
            OdometerValidator.warning(
                entered: Int.max,
                current: Int.max,
                context: .historicalRecord
            ) == nil
        )
    }
}
