//
//  FillupHistoryRow.swift
//  SocketCD
//
//  Created by Justin Risner on 9/1/26.
//

import SwiftUI

struct FillupHistoryRow: View {
    @ObservedObject var fillup: Fillup
    let isFirstFullTank: Bool

    private let settings = AppSettingsStore.shared

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                fillupDetails
                Spacer(minLength: 12)
                result
            }

            VStack(alignment: .leading, spacing: 8) {
                fillupDetails
                result
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var fillupDetails: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(fillup.date, format: .dateTime.month(.abbreviated).day().year())
                .font(.headline)

            Text("\(fillup.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var result: some View {
        if fuelEconomy > 0 {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(fuelEconomy, format: .number.precision(.fractionLength(1)))
                    .font(.headline)
                    .monospacedDigit()

                Text(settings.fuelEconomyUnit.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(status)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(.fillupsTheme))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.fillupsTheme).opacity(0.12), in: .capsule)
        }
    }

    private var fuelEconomy: Double {
        fillup.fuelEconomy()
    }

    private var status: String {
        switch fillup.fillType {
        case .partialFill: "Partial Fill"
        case .missedFill: "Full Tank (Reset)"
        case .fullTank: isFirstFullTank ? "First Full Tank" : "Full Tank"
        }
    }

    private var accessibilityDescription: String {
        let date = fillup.date.formatted(date: .long, time: .omitted)
        let odometer = "\(fillup.odometer.formatted()) \(settings.distanceUnit.rawValue)"
        let result = fuelEconomy > 0
            ? "\(fuelEconomy.formatted(.number.precision(.fractionLength(1)))) \(settings.fuelEconomyUnit.fullName)"
            : status

        return "\(date), \(result), odometer \(odometer)"
    }
}
