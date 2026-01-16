//
//  FuelEconomyChartView.swift
//  SocketCD
//
//  Created by Justin Risner on 6/30/25.
//

import Charts
import CoreData
import SwiftUI

struct FuelEconomyChartView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let settings = AppSettings.shared

    let data: [Fillup]
    let averageFuelEconomy: Double

    @Binding var selectedDateRange: DateRange
    @Binding var showingAverage: Bool
    @State private var selectedDate: Date?

    private let chartPoints: [ChartPoint]

    init(data: [Fillup], averageFuelEconomy: Double, selectedDateRange: Binding<DateRange>, showingAverage: Binding<Bool>) {
        self.data = data
        self.averageFuelEconomy = averageFuelEconomy
        self._selectedDateRange = selectedDateRange
        self._showingAverage = showingAverage

        self.chartPoints = data
            .map { ChartPoint(id: $0.objectID, date: $0.date, value: $0.fuelEconomy()) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        Chart {
            ForEach(chartPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Fuel Economy", point.value)
                )

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Fuel Economy", point.value)
                )
                .opacity(chartPoints.count == 1 ? 1 : 0)
            }
            .foregroundStyle(showingAverage ? Color.secondary.opacity(0.5) : Color.fillupsTheme)

            if let selectedPoint {
                RuleMark(x: .value("Selected Fill-up", selectedPoint.date))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .annotation(
                        position: .top,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        VStack(spacing: 2) {
                            Text(
                                "\(selectedPoint.value, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)"
                            )
                            .font(.headline)

                            Text(
                                selectedPoint.date.formatted(
                                    date: .numeric,
                                    time: .omitted
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle.adaptive
                                .fill(Color(.tertiarySystemGroupedBackground))
                                .stroke(Color.secondary, lineWidth: 0.5)
                        )
                    }

                PointMark(
                    x: .value("Date", selectedPoint.date),
                    y: .value("Fuel Economy", selectedPoint.value)
                )
                .foregroundStyle(Color.fillupsTheme)
            }

            RuleMark(y: .value("Average", averageFuelEconomy))
                .foregroundStyle(Color.fillupsTheme)
                .opacity(showingAverage ? 1 : 0)
        }
        .animation(.easeInOut, value: data)
        .animation(.easeInOut, value: selectedDateRange)
        .animation(.easeInOut, value: showingAverage)
        .chartYScale(domain: yRange)
        .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
        .chartXScale(domain: xRange)
        .chartXSelection(value: $selectedDate)
        .frame(height: horizontalSizeClass == .regular ? 350 : 200)
        .chartPlotStyle { proxy in
            proxy.background(
                Color(.systemGroupedBackground).opacity(0.3)
            )
        }
    }
    
    // MARK: - Computed Properties

    // Returns the point closest to selectedDate
    private var selectedPoint: ChartPoint? {
        guard let selectedDate else { return nil }
        return nearestPoint(to: selectedDate)
    }

    // Returns the chart point to snap to
    private func nearestPoint(to date: Date) -> ChartPoint? {
        guard !chartPoints.isEmpty else { return nil }

        var low = 0
        var high = chartPoints.count - 1

        while low <= high {
            let mid = (low + high) / 2
            let midDate = chartPoints[mid].date

            if midDate == date {
                return chartPoints[mid]
            } else if midDate < date {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        // `low` is now the insertion point
        if low == 0 {
            return chartPoints.first
        }
        if low >= chartPoints.count {
            return chartPoints.last
        }

        let before = chartPoints[low - 1]
        let after = chartPoints[low]

        return abs(before.date.timeIntervalSince(date)) <
               abs(after.date.timeIntervalSince(date))
            ? before
            : after
    }

    private var xRange: ClosedRange<Date> {
        let calendar = Calendar.current
        guard let latestDate = chartPoints.last?.date else {
            return Date()...Date()
        }

        let startOfLatestMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: latestDate)
        ) ?? latestDate

        let endOfLatestMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: startOfLatestMonth
        ) ?? latestDate

        let start: Date
        switch selectedDateRange {
        case .sixMonths:
            start = calendar.date(byAdding: .month, value: -5, to: startOfLatestMonth)!
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: startOfLatestMonth)!
        case .all:
            start = calendar.date(
                from: calendar.dateComponents(
                    [.year, .month],
                    from: chartPoints.first?.date ?? startOfLatestMonth
                )
            ) ?? startOfLatestMonth
        }

        return start...endOfLatestMonth
    }

    private var yRange: ClosedRange<Double> {
        let values = chartPoints.map(\.value)
        guard let minValue = values.min(),
              let maxValue = values.max()
        else {
            return 0...10
        }

        let step: Double = 10
        return
            floor(minValue / step) * step
            ...
            ceil(maxValue / step) * step
    }
}

struct ChartPoint: Identifiable {
    let id: NSManagedObjectID
    let date: Date
    let value: Double
}
