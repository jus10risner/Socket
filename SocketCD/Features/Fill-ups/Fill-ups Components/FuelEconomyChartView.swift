//
//  FuelEconomyChartView.swift
//  SocketCD
//
//  Created by Justin Risner on 6/30/25.
//

import Charts
import SwiftUI

struct FuelEconomyChartView: View {
    private struct Viewport {
        var position: Date = .now
        var domainLength: TimeInterval = 60 * 60 * 24 * 183
    }

    private enum Timing {
        static let fadeOut = 0.15
        static let fadeIn = 0.2
        static let scrollSettleDelay = Duration.milliseconds(350)
        static let transitionDelay = Duration.milliseconds(150)
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let data: [ChartPoint]
    let fuelEconomyUnit: FuelEconomyUnits

    @Binding var selectedDateRange: DateRange
    @State private var selectedDate: Date?
    @State private var viewport = Viewport()
    @State private var settledViewport = Viewport()
    @State private var contentOpacity = 1.0
    @State private var displayedDateRange: DateRange = .threeMonths
    @State private var resizePlotOpacity = 1.0
    @State private var chartLayoutID = 0
    @State private var resizeScrollPosition: Date?
    @State private var rangeTransitionTask: Task<Void, Never>?
    @State private var resizeTransitionTask: Task<Void, Never>?
    @State private var initialRevealProgress = 0.0

    private let selectionTolerance: TimeInterval = 60 * 60 * 24

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            chart
                .id(chartLayoutID)
                .frame(maxWidth: .infinity)
                .frame(height: horizontalSizeClass == .regular ? 350 : 200)
                .allowsHitTesting(resizePlotOpacity == 1)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width.rounded()
                } action: { oldWidth, newWidth in
                    guard oldWidth > 0, abs(newWidth - oldWidth) > 1 else {
                        return
                    }
                    
                    handleChartWidthChange()
                }
        }
        .onAppear {
            resetChartPosition()
            revealChart()
        }
        .onChange(of: selectedDateRange) {
            transitionRange()
        }
        .onChange(of: data) {
            resetChartPosition()
        }
        .task(id: viewport.position) {
            let newScrollPosition = viewport.position
            let newDomainLength = viewport.domainLength

            try? await Task.sleep(for: Timing.scrollSettleDelay)
            guard !Task.isCancelled else { return }

            withAnimation(reduceMotion ? nil : .easeOut(duration: Timing.fadeIn)) {
                settledViewport.position = newScrollPosition
                settledViewport.domainLength = newDomainLength
            }
        }
        .onDisappear {
            rangeTransitionTask?.cancel()
            resizeTransitionTask?.cancel()
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
                .font(.footnote)
                .foregroundStyle(.secondary)
            } else {
                Text("Average Fuel Economy")
                    .font(.headline)

                visibleAverageFuelEconomyValue
                    .font(.title2.bold())
                    .monospacedDigit()
                    .contentTransition(
                        .numericText(value: visibleAverageFuelEconomy ?? 0)
                    )
                    .accessibilityLabel(
                        "Average fuel economy for the visible chart range, \(visibleAverageFuelEconomyValue)"
                    )

                Text(visibleAverageDateRangeText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var visibleAverageFuelEconomyValue: Text {
        guard let average = visibleAverageFuelEconomy else {
            return Text("Not available")
        }

        return Text(
            "\(Text(average.formatted(.number.precision(.fractionLength(1)))).font(.title.bold())) \(Text(fuelEconomyUnit.displayName).font(.title3.bold()).foregroundStyle(.secondary))"
        )
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
            unit: fuelEconomyUnit
        )
    }

    private var visibleAverageDateRangeText: String {
        settledWindow.formatted(
            .interval.day().month(.abbreviated).year()
        )
    }

    private var settledWindow: Range<Date> {
        let latestValidStart = latestDate.addingTimeInterval(
            -settledViewport.domainLength
        )
        let earliestValidStart = min(
            data.first?.date ?? latestDate,
            latestValidStart
        )
        let start = min(
            max(settledViewport.position, earliestValidStart),
            latestValidStart
        )

        return start..<start.addingTimeInterval(settledViewport.domainLength)
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
            "\(Text("\(point.value, specifier: "%.1f")").font(.title.bold())) \(Text(fuelEconomyUnit.displayName).font(.title3.bold()).foregroundStyle(.secondary))"
        )
        .monospacedDigit()
        .accessibilityLabel(
            "\(point.value, specifier: "%.1f") \(fuelEconomyUnit.fullName)"
        )
    }

    private var plotOpacity: Double {
        contentOpacity * resizePlotOpacity
    }
    
    private var chart: some View {
        Chart {
            chartContent
        }
        .accessibilityLabel("Fuel economy history")
        .chartYScale(domain: yAxisDomain)
        .chartXScale(
            domain: xAxisDomain,
            range: .plotDimension(startPadding: 10, endPadding: 10)
        )
        .chartXAxis {
            AxisMarks(
                values: .stride(
                    by: .month,
                    count: displayedDateRange == .sixMonths ? 1 : 2
                )
            ) { value in
                AxisGridLine(
                    stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5])
                )
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.abbreviated))
                            .opacity(contentOpacity)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) {
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: viewport.domainLength)
        .chartScrollPosition(x: $viewport.position)
        .chartXSelection(value: $selectedDate)
        .chartOverlay { proxy in
            selectionOverlay(for: proxy)
        }
    }

    @ChartContentBuilder
    private var chartContent: some ChartContent {
        if data.count >= 2 {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Fuel Economy", revealedValue(for: point))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppSection.fillups.color.gradient)
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .opacity(plotOpacity)
            }
        }

        if data.count >= 3 {
            ForEach(data) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Minimum", yAxisDomain.lowerBound),
                    yEnd: .value("Fuel Economy", revealedValue(for: point))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppSection.fillups.color.opacity(0.3),
                            AppSection.fillups.color.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(plotOpacity)
                .accessibilityHidden(true)
            }
        } else {
            ForEach(data) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Fuel Economy", revealedValue(for: point))
                )
                .symbolSize(45)
                .foregroundStyle(AppSection.fillups.color)
                .opacity(plotOpacity)
                .accessibilityHidden(true)
            }
        }

        if let selectedPoint {
            RuleMark(
                x: .value("Selected Date", selectedPoint.date)
            )
            .foregroundStyle(Color.secondary)
            .lineStyle(StrokeStyle(lineWidth: 1))
            .opacity(plotOpacity)
            .accessibilityHidden(true)
        }
    }

    private func selectionOverlay(for proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selectedPoint,
               let plotFrame = proxy.plotFrame,
               let xPosition = proxy.position(forX: selectedPoint.date),
               let yPosition = proxy.position(forY: selectedPoint.value) {
                let frame = geometry[plotFrame]

                Circle()
                    .fill(AppSection.fillups.color)
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

    private func revealedValue(for point: ChartPoint) -> Double {
        yAxisDomain.lowerBound
            + ((point.value - yAxisDomain.lowerBound) * initialRevealProgress)
    }

    private func revealChart() {
        guard initialRevealProgress == 0 else { return }

        if reduceMotion {
            initialRevealProgress = 1
        } else {
            withAnimation(.easeInOut.delay(Timing.fadeIn)) {
                initialRevealProgress = 1
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
            -viewport.domainLength
        )
        let earliestDate = data.first?.date ?? latestDate

        return min(earliestDate, windowStart)...latestDate
    }

    private var targetViewport: Viewport {
        let domainLength = selectedDateRange.chartDuration
        return Viewport(
            position: latestDate.addingTimeInterval(-domainLength),
            domainLength: domainLength
        )
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

        let visibleStart = viewport.position.addingTimeInterval(-selectionTolerance)
        let visibleEnd = viewport.position
            .addingTimeInterval(viewport.domainLength + selectionTolerance)

        guard point.date >= visibleStart, point.date <= visibleEnd else {
            return nil
        }

        return point
    }

    private func resetChartPosition() {
        rangeTransitionTask?.cancel()
        resizeTransitionTask?.cancel()
        resizeScrollPosition = nil
        resizePlotOpacity = 1
        selectedDate = nil
        contentOpacity = 1
        displayedDateRange = selectedDateRange
        let newViewport = targetViewport
        viewport = newViewport
        settledViewport = newViewport
    }

    private func handleChartWidthChange() {
        rangeTransitionTask?.cancel()
        
        if resizeScrollPosition == nil {
            resizeScrollPosition = settledViewport.position
            selectedDate = nil
            
            if reduceMotion {
                resizePlotOpacity = 0
            } else {
                withAnimation(.easeOut(duration: Timing.fadeOut)) {
                    resizePlotOpacity = 0
                }
            }
        }
        
        resizeTransitionTask?.cancel()
        resizeTransitionTask = Task { @MainActor in
            try? await Task.sleep(for: Timing.transitionDelay)
            guard !Task.isCancelled,
                  let resizeScrollPosition else { return }
            
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                viewport.position = resizeScrollPosition
                settledViewport.position = resizeScrollPosition
                selectedDate = nil
                chartLayoutID += 1
                self.resizeScrollPosition = nil
            }
            
            if reduceMotion {
                resizePlotOpacity = 1
            } else {
                withAnimation(.easeIn(duration: Timing.fadeIn)) {
                    resizePlotOpacity = 1
                }
            }
        }
    }
    
    private func transitionRange() {
        rangeTransitionTask?.cancel()
        resizeTransitionTask?.cancel()
        resizeScrollPosition = nil
        selectedDate = nil

        let newViewport = targetViewport

        guard !reduceMotion else {
            viewport = newViewport
            settledViewport = newViewport
            contentOpacity = 1
            displayedDateRange = selectedDateRange
            return
        }

        rangeTransitionTask = Task { @MainActor in
            withAnimation(.easeOut(duration: Timing.fadeOut)) {
                contentOpacity = 0
            }

            try? await Task.sleep(for: Timing.transitionDelay)
            guard !Task.isCancelled else { return }

            viewport = newViewport
            displayedDateRange = selectedDateRange

            withAnimation(.easeIn(duration: Timing.fadeIn)) {
                contentOpacity = 1
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
