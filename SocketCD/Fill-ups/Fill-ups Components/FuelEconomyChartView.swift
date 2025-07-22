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
//    let fillups: FetchedResults<Fillup>
    let fillups: [Fillup]
    
    @State private var selectedDateRange: DateRange = .threeMonths
    @State private var selectedDate: Date? = nil
    
    var body: some View {
        VStack(spacing: 15) {
            Chart(data) { fillup in
                LineMark(x: .value("Date", fillup.date), y: .value("MPG", fillup.fuelEconomy(settings: settings)))
            }
            .animation(.easeInOut(duration: 0.5), value: visibleRange)
            .chartYScale(domain: yRange)
            .chartXScale(domain: visibleRange)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only select a date if it lies within the visible bounds of the chart
                                    if value.location.x >= 0 && value.location.x <= geo.size.width {
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            selectedDate = nearestDate(to: date)
                                        }
                                    } else {
                                        // If drag gesture moves out of bounds, clear selection
                                        selectedDate = nil
                                    }
                                }
                                .onEnded { _ in
                                    selectedDate = nil
                                }
                        )
                    
                    if let selectedDate = selectedDate,
                       let selectedFillup = data.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }),
                       let xPosition = proxy.position(forX: selectedFillup.date),
                       let yPosition = proxy.position(forY: selectedFillup.fuelEconomy(settings: settings))
                    {
                        // Vertical line
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: 1, height: geo.size.height)
                            .position(x: xPosition, y: geo.size.height / 2)
                        
                        Circle()
                            .fill(Color.defaultFillupsAccent)
                            .frame(width: 10, height: 10)
                            .position(x: xPosition, y: yPosition)
//
//                            // Tooltip
//                            Text(String(format: "%.1f", selectedFillup.fuelEconomy))
//                                .font(.caption)
//                                .padding(5)
//                                .background(.regularMaterial)
//                                .cornerRadius(5)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5)
//                                )
//                                .position(x: xPosition, y: yPosition)
                    }
                    
                    // Average fuel economy line
                    if let plotFrameAnchor = proxy.plotFrame,
                        let yPos = proxy.position(forY: averageFuelEconomy) {
                        let plotFrame = geo[plotFrameAnchor]
                        
                        Path { path in
                            path.move(to: CGPoint(x: plotFrame.minX, y: yPos))
                            path.addLine(to: CGPoint(x: plotFrame.maxX, y: yPos))
                        }
                        .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                }
            }
            .frame(minHeight: 200)
//            .aspectRatio(2, contentMode: .fit)
            .padding(5)
            .clipShape(Rectangle())
            .tint(settings.accentColor(for: .fillupsTheme).gradient)
//            .overlay {
//                VStack {
//                    if let selectedDate,
//                       let selectedFillup = data.first(where: { $0.date == selectedDate }) {
//                        Text(String(format: "%.1f mpg", selectedFillup.fuelEconomy))
//                            .font(.headline)
//                            .padding(.bottom, 4)
//                    }
//                    
//                    Spacer()
//                }
//            }
            
            Picker("Date Range", selection: $selectedDateRange) {
                ForEach(DateRange.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)
            
            Divider()
            
            LabeledContent("Average") {
                Text(averageFuelEconomy == 0 ? "No Data" : "\(averageFuelEconomy, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
            }
        }
    }
    
    // Determines which data points to plot (excludes those with fuel economy of 0)
    private var data: [Fillup] {
        let dataPoints = fillups.compactMap { fillup in
            fillup.fuelEconomy(settings: settings) != 0 ? fillup : nil
        }
        
        return dataPoints
    }
    
    // Calculates the average fuel economy for a given date range
    private var averageFuelEconomy: Double {
        let now = Date()

        func computeAverage(from startDate: Date) -> Double {
            let dataSet = data.filter { $0.date > startDate }
            guard !dataSet.isEmpty else { return 0 }
            let total = dataSet.reduce(0) { $0 + $1.fuelEconomy(settings: settings) }
            return total / Double(dataSet.count)
        }
        
        switch selectedDateRange {
        case .threeMonths:
            guard let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: now) else { return 0 }
            return computeAverage(from: threeMonthsAgo)
        case .sixMonths:
            guard let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) else { return 0 }
            return computeAverage(from: sixMonthsAgo)
        case .year:
            guard let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) else { return 0 }
            return computeAverage(from: oneYearAgo)
        case .all:
            guard !data.isEmpty else { return 0 }
            let total = data.reduce(0) { $0 + $1.fuelEconomy(settings: settings) }
            return total / Double(data.count)
        }
    }
    
    // Determines the visible horizontal area of the chart
    var visibleRange: ClosedRange<Date> {
        let end = Date()
        let start: Date

        switch selectedDateRange {
        case .threeMonths:
            start = Calendar.current.date(byAdding: .month, value: -3, to: end) ?? end
        case .sixMonths:
            start = Calendar.current.date(byAdding: .month, value: -6, to: end) ?? end
        case .year:
            start = Calendar.current.date(byAdding: .year, value: -1, to: end) ?? end
        case .all:
            start = data.last?.date ?? end
        }

        return start...end
    }
    
    // Determines the vertical scale of the chart
    private var yRange: ClosedRange<Double> {
//        let sortedArray = data.map(\.fuelEconomy)
        let sortedArray = data.map { $0.fuelEconomy(settings: settings) }
        guard let minValue = sortedArray.min(), let maxValue = sortedArray.max() else { return 0...1 } // default to 0...1 if sortedArray is empty
        
        let padding = (maxValue - minValue) * 0.1 // Used to give LineMark some breathing room on the y-axis
        return max(minValue - padding, 0)...(maxValue + padding) // max() ensures that the y-axis value never goes below 0
    }
    
    private func nearestDate(to target: Date) -> Date? {
        data.min(by: { abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target)) })?.date
    }
}

//#Preview {
//    FuelEconomyChartView(data: [23.4, 22.6, 26.4, 30.1, 23.9, 24.2, 28.7], average: 25.6)
//}
