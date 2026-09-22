//
//  FuelEconomySetupView.swift
//  SocketCD
//

import SwiftUI

enum FuelEconomySetupState: Equatable {
    case needsBaseline
    case needsFullTank

    var title: LocalizedStringResource {
        switch self {
        case .needsBaseline:
            "Two full tanks to go"
        case .needsFullTank:
            "One more full tank"
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .needsBaseline:
            "Log a Full Tank now, then another the next time you refuel."
        case .needsFullTank:
            "Your fuel economy chart will be ready after your next Full Tank fill-up."
        }
    }

    var hasBaseline: Bool {
        self != .needsBaseline
    }

}

struct FuelEconomySetupView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let state: FuelEconomySetupState

    var body: some View {
        VStack(spacing: 22) {
            FuelEconomyProgressView(state: state)
            
            FuelEconomySetupSummary(
                title: state.title,
                message: state.message
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(
            minHeight: horizontalSizeClass == .regular ? 350 : 200
        )
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.title)
        .accessibilityValue(state.message)
    }
}

private struct FuelEconomySetupSummary: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 300)
    }
}

private struct FuelEconomyProgressView: View {
    let state: FuelEconomySetupState

    var body: some View {
        HStack(spacing: 12) {
            if !state.hasBaseline {
                FuelEconomyActionSymbol(status: .current)

                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            FuelEconomyActionSymbol(
                status: state.hasBaseline ? .current : .upcoming
            )

            Image(systemName: "arrow.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.fillupsTheme)

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.fillupsTheme)
                .frame(width: 52, height: 52)
                .background(
                    Color.fillupsTheme.opacity(0.12),
                    in: Circle()
                )
        }
        .accessibilityHidden(true)
    }

}

private struct FuelEconomyActionSymbol: View {
    enum Status: Equatable {
        case current
        case upcoming
    }

    let status: Status

    var body: some View {
        Image(systemName: "fuelpump.fill")
            .font(.title3.weight(.semibold))
            .foregroundStyle(symbolColor)
            .frame(width: 52, height: 52)
            .background(backgroundColor, in: Circle())
            .overlay {
                if status == .current {
                    Circle()
                        .stroke(
                            Color.fillupsTheme.opacity(0.55),
                            lineWidth: 1.5
                        )
                }
            }
    }

    private var symbolColor: Color {
        switch status {
        case .current:
            .fillupsTheme
        case .upcoming:
            .secondary.opacity(0.55)
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .current:
            .fillupsTheme.opacity(0.12)
        case .upcoming:
            .secondary.opacity(0.08)
        }
    }
}
