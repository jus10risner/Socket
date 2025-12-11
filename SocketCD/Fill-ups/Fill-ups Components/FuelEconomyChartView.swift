//
//  FuelEconomyChartView.swift
//  SocketCD
//
//  Created by Justin Risner on 6/30/25.
//

import Charts
import SwiftUI

struct FuelEconomyChartView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let settings = AppSettings.shared
    let data: [Fillup]
    let averageFuelEconomy: Double
    
    @Binding var selectedDateRange: DateRange
    @Binding var showingAverage: Bool
    @State private var selectedDate: Date?
    
    private var selectedFillup: Fillup? { // Used to populate information in the annotation
        guard let selectedDate else { return nil }
        
        return data.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) })
    }
    
    var body: some View {
        Chart {
            ForEach(data) { fillup in
                LineMark(x: .value("Date", fillup.date), y: .value("Fuel Economy", fillup.fuelEconomy()))
                
                PointMark(x: .value("Date", fillup.date), y: .value("Fuel Economy", fillup.fuelEconomy()))
                    .opacity(data.count == 1 ? 1 : 0) // Vislble only when a single data point is available; also serves to make animation between data sets more fluid
            }
            .foregroundStyle(showingAverage ? Color.secondary.opacity(0.5) : Color.fillupsTheme)
            
            if let selectedFillup {
                RuleMark(x: .value("Selected Fill-up", selectedFillup.date))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(spacing: 2) {
                            Text("\(selectedFillup.fuelEconomy(), specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                                .font(.headline)
                            
                            Text(selectedFillup.date.formatted(date: .numeric, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle.adaptive
                                .fill(Color(.tertiarySystemGroupedBackground))
                                .stroke(Color.secondary, lineWidth: 0.5)
                        )
                    }
                
                PointMark(x: .value("Date", selectedFillup.date), y: .value("Fuel Economy", selectedFillup.fuelEconomy()))
                    .foregroundStyle(Color(.fillupsTheme))
            }
            
            if showingAverage {
                RuleMark(y: .value("Average", averageFuelEconomy))
                    .foregroundStyle(Color.fillupsTheme)
            }
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
            proxy
                .background(Color(.systemGroupedBackground).opacity(0.3))
        }
    }
    
    // The horizontal scale of the chart
    private var xRange: ClosedRange<Date> {
        let calendar = Calendar.current

        guard let latestDate = data.last?.date else {
            return Date()...Date()
        }

        // Anchor to the start of the latest month
        let startOfLatestMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: latestDate)
        ) ?? latestDate

        // End is the start of the next month after the latest month
        let endOfLatestMonth = calendar.date(byAdding: .month, value: 1, to: startOfLatestMonth) ?? latestDate

        // Compute start based on the selected range
        let start: Date
        switch selectedDateRange {
        case .sixMonths:
            start = calendar.date(byAdding: .month, value: -5, to: startOfLatestMonth) ?? startOfLatestMonth
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: startOfLatestMonth) ?? startOfLatestMonth
        case .all:
            if let earliestDate = data.first?.date {
                start = calendar.date(from: calendar.dateComponents([.year, .month], from: earliestDate)) ?? earliestDate
            } else {
                start = startOfLatestMonth
            }
        }

        return start...endOfLatestMonth
    }
    
    // The vertical scale of the chart
    private var yRange: ClosedRange<Double> {
        let values = data.map { $0.fuelEconomy() }
        guard let minValue = values.min(), let maxValue = values.max() else { return 0...10 } // default to 0...5 if values is empty
        
        let step: Double = 10 // The number to round by
        let lowerBound = floor(minValue / step) * step
        let upperBound = ceil(maxValue / step) * step
        return lowerBound...upperBound
    }
}
