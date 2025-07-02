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
    let fillups: FetchedResults<Fillup>
    
    @State private var selectedDateRange: DateRange = .threeMonths
    @State private var selectedDate: Date? = nil
    
    private var data: [Fillup] {
        let dataPoints = fillups.compactMap { fillup in
            fillup.fuelEconomy != 0 ? fillup : nil
        }
        
        return dataPoints
        
//        switch selectedDateRange {
//        case .threeMonths:
//            guard let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date.now) else { return [] }
//            return dataPoints.filter { $0.date > threeMonthsAgo }
//        case .sixMonths:
//            guard let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date.now) else { return [] }
//            return dataPoints.filter { $0.date > sixMonthsAgo }
//        case .year:
//            guard let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date.now) else { return [] }
//            return dataPoints.filter { $0.date > oneYearAgo }
//        case .all:
//            return dataPoints
//        }
    }
    
    private var averageFuelEconomy: Double {
        let totalDistance = data.reduce(0) { $0 + $1.tripDistance }
        let totalFuel = data.reduce(0) { $0 + $1.volume }

        if settings.fuelEconomyUnit == .L100km {
            return (totalFuel / Double(totalDistance)) * 100
        } else {
            return Double(totalDistance) / totalFuel
        }
    }
    
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
    
//    private var xRange: ClosedRange<Date> {
//        let sortedArray = data.map(\.date)
//        let minDate = sortedArray.min() ?? Date.now
//        let maxDate = sortedArray.max() ?? Date.now
//        return minDate...maxDate
//    }
    
    private var yRange: ClosedRange<Double> {
        let sortedArray = data.map(\.fuelEconomy)
        let minValue = sortedArray.min()?.rounded() ?? 0
        let maxValue = sortedArray.max()?.rounded() ?? 0
        return (minValue - 5).rounded(.down)...(maxValue + 5).rounded(.up)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Chart(data) { fillup in
                LineMark(x: .value("Date", fillup.date), y: .value("MPG", fillup.fuelEconomy))
                    .interpolationMethod(.catmullRom)
                    .symbol(.circle)
                
                RuleMark(y: .value("Average", averageFuelEconomy))
                    .foregroundStyle(Color.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                //                    .annotation(position: .top, alignment: .leading) {
                //                        Text("Avg: \(averageFuelEconomy, specifier: "%.1f") mpg")
                //                            .font(.caption)
                //                            .foregroundColor(.secondary)
                //                    }
            }
            .animation(.easeInOut(duration: 0.5), value: visibleRange)
            .chartYScale(domain: yRange)
            .chartXScale(domain: visibleRange)
//            .chartXAxis {
////                AxisMarks(values: .stride(by: .month)) { value in
////                    AxisValueLabel(format: .dateTime.month(.abbreviated))
////                }
////                AxisMarks(preset: .extended, values: .automatic) { value in
////                    AxisValueLabel()
//                }
//            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
//                                    let location = value.location
//                                    if let date: Date = proxy.value(atX: location.x) {
//                                        selectedDate = nearestDate(to: date)
//                                    }
                                    // Check if location.x is inside chart bounds
                                    if value.location.x >= 0 && value.location.x <= geo.size.width {
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            selectedDate = nearestDate(to: date)
                                        }
                                    } else {
                                        // Out of bounds: clear selection
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
                       let yPosition = proxy.position(forY: selectedFillup.fuelEconomy)
                    {
                        // Vertical line
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: 1, height: 200)
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
                }
            }
            .frame(minHeight: 200)
            .padding(.leading, 5)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .tint(Color.defaultFillupsAccent.gradient)
            .overlay {
                VStack {
                    if let selectedDate,
                       let selectedFillup = data.first(where: { $0.date == selectedDate }) {
                        Text(String(format: "%.1f mpg", selectedFillup.fuelEconomy))
                            .font(.headline)
                            .padding(.bottom, 4)
                    }
                    
                    Spacer()
                }
            }
            
            Picker("Date Range", selection: $selectedDateRange) {
                ForEach(DateRange.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)
            
            Divider()
            
            LabeledContent("Average") {
                Text("\(averageFuelEconomy, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
            }
        }
//        .onAppear {
//            data = generateData(for: selectedDateRange)
//        }
//        .onChange(of: selectedDateRange) {
//            withAnimation {
//                data = generateData(for: selectedDateRange)
//            }
//        }
    }
    
    private func nearestDate(to target: Date) -> Date? {
        data.min(by: { abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target)) })?.date
    }
}

//#Preview {
//    FuelEconomyChartView(data: [23.4, 22.6, 26.4, 30.1, 23.9, 24.2, 28.7], average: 25.6)
//}
