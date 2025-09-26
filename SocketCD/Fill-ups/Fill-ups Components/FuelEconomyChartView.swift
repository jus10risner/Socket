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
    let fillups: [Fillup]
    
    @State private var selectedDateRange: DateRange = .sixMonths
    @State private var selectedDate: Date?
    
    private var selectedFillup: Fillup? { // Used to populate information in the annotation
        guard let selectedDate else { return nil }
        
        return data.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) })
    }
    
    var body: some View {
        ZStack {
            if data.count == 0 {
                emptyChartView
            } else {
                VStack(alignment: .leading) {
                    Chart {
                        if let selectedFillup {
                            RuleMark(x: .value("Selected Fill-up", selectedFillup.date))
                                .foregroundStyle(Color.secondary.opacity(0.3))
                                .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                    VStack {
                                        Text(selectedFillup.date.formatted(date: .numeric, time: .omitted))
                                            .font(.subheadline.bold())
                                        
                                        Text("\(selectedFillup.fuelEconomy(settings: settings), specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                                            .font(.title3.bold())
                                    }
                                    .foregroundStyle(Color.white)
                                    .padding()
                                    .frame(width: 130)
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
                    
                    Picker("Date Range", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical)
                    
                    Divider()
                    
                    LabeledContent("Average") {
                        if let averageFuelEconomy {
                            Text("\(averageFuelEconomy, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                        }
                    }
                }
            }
        }
    }

    // Determines which data points to plot (excludes those with fuel economy of 0)
    private var data: [Fillup] {
        let calendar = Calendar.current
        guard let latestDate = fillups.compactMap(\.date).max() else { return [] }

        // Start of latest month
        let startOfLatestMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: latestDate)) ?? latestDate
        
        let cutoff: Date?
        switch selectedDateRange {
        case .sixMonths:
            cutoff = calendar.date(byAdding: .month, value: -5, to: startOfLatestMonth)
        case .year:
            cutoff = calendar.date(byAdding: .year, value: -1, to: startOfLatestMonth)
        case .all:
            cutoff = nil
        }

        return fillups
            .filter { fillup in
                fillup.fuelEconomy(settings: settings) != 0 &&
                (cutoff.map { fillup.date >= $0 } ?? true)
            }
            .sorted(by: { $0.date < $1.date })
    }
    
    // Returns the average fuel economy for a given set of fill-ups
    private var averageFuelEconomy: Double? {
        guard !data.isEmpty else { return nil }
        let total = data.map { $0.fuelEconomy(settings: settings) }.reduce(0, +)
        
        return total / Double(data.count)
    }
    
    // Determines the horizontal scale of the chart
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
    
    // Determines the vertical scale of the chart
    private var yRange: ClosedRange<Double> {
        let values = data.map { $0.fuelEconomy(settings: settings) }
        guard let minValue = values.min(), let maxValue = values.max() else { return 0...10 } // default to 0...5 if values is empty
        
        let step: Double = 10 // The number to round by
        let lowerBound = floor(minValue / step) * step
        let upperBound = ceil(maxValue / step) * step
        return lowerBound...upperBound
    }
    
    // Displayed when no data points exist to place on the chart
    private var emptyChartView: some View {
        ContentUnavailableView {
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                
                Text("One more to go")
                    .font(.title2.bold())
                    .foregroundStyle(Color.primary)
            }
        } description: {
            Text("Add another **Full Tank** fill-up to see your fuel economy chart.")
        }
    }
}
