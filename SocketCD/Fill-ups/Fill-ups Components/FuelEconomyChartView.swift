//
//  FuelEconomyChartView.swift
//  SocketCD
//
//  Created by Justin Risner on 6/30/25.
//

import Charts
import SwiftUI

struct FuelEconomyChartView: View {
    @EnvironmentObject private var settings: AppSettings
    let data: [Fillup]
    let averageFuelEconomy: Double
    
    @Binding var selectedDateRange: DateRange
    @State private var selectedDate: Date?
    
    private var selectedFillup: Fillup? { // Used to populate information in the annotation
        guard let selectedDate else { return nil }
        
        return data.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) })
    }
    
    var body: some View {
        Chart {
            if let selectedFillup {
                RuleMark(x: .value("Selected Fill-up", selectedFillup.date))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(spacing: 2) {
                            Text(selectedFillup.date.formatted(date: .numeric, time: .omitted))
                                .font(.caption)
                            
                            Text("\(selectedFillup.fuelEconomy(settings: settings), specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                                .font(.footnote.bold())
                        }
                        .foregroundStyle(Color.white)
                        .padding()
                        .background(RoundedRectangle.adaptive.fill(settings.accentColor(for: .fillupsTheme).gradient))
                    }
                
                PointMark(x: .value("Date", selectedFillup.date), y: .value("Fuel Economy", selectedFillup.fuelEconomy(settings: settings)))
            }
            
            ForEach(data) { fillup in
                LineMark(x: .value("Date", fillup.date), y: .value("Fuel Economy", fillup.fuelEconomy(settings: settings)))
                
                PointMark(x: .value("Date", fillup.date), y: .value("Fuel Economy", fillup.fuelEconomy(settings: settings)))
                    .opacity(data.count == 1 ? 1 : 0) // Vislble only when a single data point is available; also serves to make animation between data sets more fluid
            }
            .foregroundStyle(settings.accentColor(for: .fillupsTheme))
            
            
        }
        .animation(.easeInOut, value: selectedDateRange)
        .chartYScale(domain: yRange)
        .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
        .chartXScale(domain: xRange)
        .chartXSelection(value: $selectedDate)
        .frame(minHeight: 200)
    }
    
    // The horizontal scale of the chart
    private var xRange: ClosedRange<Date> {
        let calendar = Calendar.current
        
        guard
            let earliestDate = data.first?.date,
            let latestDate = data.last?.date
        else {
            return Date()...Date()
        }
        
        let startOfLatestMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: latestDate)) ?? latestDate
        let endOfLatestMonth = calendar.date(byAdding: .month, value: 1, to: startOfLatestMonth) ?? latestDate

        let start: Date
        let end: Date = endOfLatestMonth
        
        switch selectedDateRange {
        case .sixMonths:
            if let sixMonthsBack = calendar.date(byAdding: .month, value: -5, to: startOfLatestMonth),
               let earliestMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: earliestDate)) {
                start = max(sixMonthsBack, earliestMonth)
            } else {
                start = earliestDate
            }
            
        case .year:
            if let oneYearBack = calendar.date(byAdding: .year, value: -1, to: startOfLatestMonth),
               let earliestMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: earliestDate)) {
                start = max(oneYearBack, earliestMonth)
            } else {
                start = earliestDate
            }
            
        case .all:
            start = calendar.date(from: calendar.dateComponents([.year, .month], from: earliestDate)) ?? earliestDate
        }
        
        return start...end
    }
    
    // The vertical scale of the chart
    private var yRange: ClosedRange<Double> {
        let values = data.map { $0.fuelEconomy(settings: settings) }
        guard let minValue = values.min(), let maxValue = values.max() else { return 0...10 } // default to 0...5 if values is empty
        
        let step: Double = 10 // The number to round by
        let lowerBound = floor(minValue / step) * step
        let upperBound = ceil(maxValue / step) * step
        return lowerBound...upperBound
    }
}
