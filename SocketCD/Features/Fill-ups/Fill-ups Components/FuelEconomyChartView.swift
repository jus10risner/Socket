//
//  FuelEconomyChartView.swift
//  SocketCD
//
//  Created by Justin Risner on 6/30/25.
//

import Charts
import SwiftUI

struct FuelEconomyChartView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let data: [ChartPoint]

    @Binding var selectedDateRange: DateRange
    @State private var selectedDate: Date?
    @State private var scrollPosition: Date = .now
    @State private var settledScrollPosition: Date = .now
    @State private var visibleDomainLength: TimeInterval = 60 * 60 * 24 * 183
    @State private var settledDomainLength: TimeInterval = 60 * 60 * 24 * 183
    @State private var chartOpacity = 1.0
    @State private var rangeTransitionTask: Task<Void, Never>?

    private let settings = AppSettingsStore.shared
    private let selectionTolerance: TimeInterval = 60 * 60 * 24

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            chart
                .opacity(chartOpacity)
                .frame(height: horizontalSizeClass == .regular ? 350 : 200)
        }
        .onAppear {
            resetChartPosition()
        }
        .onChange(of: selectedDateRange) {
            transitionRange()
        }
        .onChange(of: data) {
            resetChartPosition()
        }
        .task(id: scrollPosition) {
            let newScrollPosition = scrollPosition
            let newDomainLength = visibleDomainLength

            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                settledScrollPosition = newScrollPosition
                settledDomainLength = newDomainLength
            }
        }
        .onDisappear {
            rangeTransitionTask?.cancel()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let selectedPoint {
                Text("Selected Fuel Economy")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                fuelEconomyText(for: selectedPoint)

                Text(
                    selectedPoint.date,
                    format: .dateTime.month(.abbreviated).day().year()
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text("Average Fuel Economy")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(visibleAverageFuelEconomyValue)
                    .font(.title2.bold())
                    .monospacedDigit()
                    .contentTransition(
                        .numericText(value: visibleAverageFuelEconomy ?? 0)
                    )
                    .accessibilityLabel(
                        "Average fuel economy for the visible chart range, \(visibleAverageFuelEconomyValue)"
                    )

                Text(visibleAverageDateRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var visibleAverageFuelEconomyValue: String {
        guard let average = visibleAverageFuelEconomy else {
            return "Not available"
        }

        return "\(average.formatted(.number.precision(.fractionLength(1)))) \(settings.fuelEconomyUnit.rawValue)"
    }

    private var visibleAverageFuelEconomy: Double? {
        let window = settledWindow
        let startIndex = insertionIndex(for: window.lowerBound)
        let endIndex = insertionIndex(
            for: window.upperBound,
            afterMatches: true
        )

        guard startIndex < endIndex else { return nil }

        return ChartPoint.aggregateFuelEconomy(
            from: data[startIndex..<endIndex],
            unit: settings.fuelEconomyUnit
        )
    }

    private var visibleAverageDateRangeText: String {
        settledWindow.formatted(
            .interval.day().month(.abbreviated).year()
        )
    }

    private var settledWindow: Range<Date> {
        let latestValidStart = latestDate.addingTimeInterval(
            -settledDomainLength
        )
        let earliestValidStart = min(
            data.first?.date ?? latestDate,
            latestValidStart
        )
        let start = min(
            max(settledScrollPosition, earliestValidStart),
            latestValidStart
        )

        return start..<start.addingTimeInterval(settledDomainLength)
    }

    private func insertionIndex(for date: Date, afterMatches: Bool = false) -> Int {
        var low = 0
        var high = data.count

        while low < high {
            let middle = (low + high) / 2
            let middleDate = data[middle].date
            if middleDate < date || (afterMatches && middleDate == date) {
                low = middle + 1
            } else {
                high = middle
            }
        }

        return low
    }

    private func fuelEconomyText(for point: ChartPoint) -> some View {
        Text(
            "\(point.value, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)"
        )
        .font(.title2.bold())
        .monospacedDigit()
        .accessibilityLabel(
            "\(point.value, specifier: "%.1f") \(settings.fuelEconomyUnit.fullName)"
        )
    }

    private var chart: some View {
        Chart {
            if data.count >= 2 {
                LinePlot(
                    data,
                    x: .value("Date", \.date),
                    y: .value("Fuel Economy", \.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.fillupsTheme.gradient)
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }

            if data.count >= 3 {
                AreaPlot(
                    data,
                    x: .value("Date", \.date),
                    yStart: .value("Minimum", yAxisDomain.lowerBound),
                    yEnd: .value("Fuel Economy", \.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.fillupsTheme.opacity(0.3),
                            Color.fillupsTheme.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .accessibilityHidden(true)
            } else {
                PointPlot(
                    data,
                    x: .value("Date", \.date),
                    y: .value("Fuel Economy", \.value)
                )
                .symbolSize(45)
                .foregroundStyle(Color.fillupsTheme)
                .accessibilityHidden(true)
            }

            if let selectedPoint {
                RuleMark(
                    x: .value("Selected Date", selectedPoint.date)
                )
                .foregroundStyle(Color.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .accessibilityHidden(true)
            }
        }
        .accessibilityLabel("Fuel economy history")
        .chartYScale(domain: yAxisDomain)
        .chartXScale(
            domain: xAxisDomain,
            range: .plotDimension(startPadding: 3, endPadding: 3)
        )
        .chartXAxis {
            AxisMarks(
                values: .stride(
                    by: .month,
                    count: selectedDateRange == .sixMonths ? 1 : 2
                )
            ) {
                AxisGridLine(
                    stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5])
                )
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) {
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleDomainLength)
        .chartScrollPosition(x: $scrollPosition)
        .chartXSelection(value: $selectedDate)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let selectedPoint,
                   let plotFrame = proxy.plotFrame,
                   let xPosition = proxy.position(forX: selectedPoint.date),
                   let yPosition = proxy.position(forY: selectedPoint.value) {
                    let frame = geometry[plotFrame]

                    Circle()
                        .fill(Color.fillupsTheme)
                        .frame(width: 14, height: 14)
                        .position(
                            x: frame.origin.x + xPosition,
                            y: frame.origin.y + yPosition
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var latestDate: Date {
        data.last?.date ?? .now
    }

    private var yAxisDomain: ClosedRange<Double> {
        guard let minimum = data.min(by: { $0.value < $1.value })?.value,
              let maximum = data.max(by: { $0.value < $1.value })?.value
        else { return 0...10 }

        return (floor(minimum) - 1)...(ceil(maximum) + 1)
    }

    private var xAxisDomain: ClosedRange<Date> {
        let windowStart = latestDate.addingTimeInterval(
            -visibleDomainLength
        )
        let earliestDate = data.first?.date ?? latestDate

        return min(earliestDate, windowStart)...latestDate
    }

    private var targetDomainLength: TimeInterval {
        selectedDateRange.chartDuration
    }

    private var selectedPoint: ChartPoint? {
        guard let selectedDate, !data.isEmpty else { return nil }

        let index = insertionIndex(for: selectedDate)

        let point: ChartPoint
        if index == 0 {
            point = data[0]
        } else if index == data.count {
            point = data[data.count - 1]
        } else {
            let before = data[index - 1]
            let after = data[index]
            point = abs(before.date.timeIntervalSince(selectedDate)) <
                abs(after.date.timeIntervalSince(selectedDate))
                ? before
                : after
        }

        let visibleStart = scrollPosition.addingTimeInterval(-selectionTolerance)
        let visibleEnd = scrollPosition
            .addingTimeInterval(visibleDomainLength + selectionTolerance)

        guard point.date >= visibleStart, point.date <= visibleEnd else {
            return nil
        }

        return point
    }

    private func resetChartPosition() {
        rangeTransitionTask?.cancel()
        selectedDate = nil
        chartOpacity = 1
        let newDomainLength = targetDomainLength
        let newScrollPosition = latestDate.addingTimeInterval(
            -newDomainLength
        )
        visibleDomainLength = newDomainLength
        settledDomainLength = newDomainLength
        scrollPosition = newScrollPosition
        settledScrollPosition = newScrollPosition
    }

    private func transitionRange() {
        rangeTransitionTask?.cancel()
        selectedDate = nil

        let newDomainLength = targetDomainLength
        let newScrollPosition = latestDate.addingTimeInterval(
            -newDomainLength
        )

        guard !reduceMotion else {
            visibleDomainLength = newDomainLength
            settledDomainLength = newDomainLength
            scrollPosition = newScrollPosition
            settledScrollPosition = newScrollPosition
            chartOpacity = 1
            return
        }

        rangeTransitionTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.15)) {
                chartOpacity = 0
            }

            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            visibleDomainLength = newDomainLength
            scrollPosition = newScrollPosition

            withAnimation(.easeIn(duration: 0.2)) {
                chartOpacity = 1
            }
        }
    }
}

private extension DateRange {
    var chartDuration: TimeInterval {
        switch self {
        case .threeMonths: 60 * 60 * 24 * 90
        case .sixMonths: 60 * 60 * 24 * 183
        case .year: 60 * 60 * 24 * 365
        }
    }
}
