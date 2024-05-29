//
//  FillupsDashboardView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct FillupsDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var vehicle: Vehicle
    
    @FetchRequest var fillups: FetchedResults<Fillup>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._fillups = FetchRequest(
            entity: Fillup.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Fillup.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var showingAddFillup = false
    @State private var showingfuelEconomyInfo = false
    
    @State private var animatingTrendArrow = false
    @State private var fuelEconomyDataPoints: [Double] = []
    
    @State private var selectedDateRange: DateRange = .sixMonths
    
    var body: some View {
        fillupsDashboard
    }
    
    
    // MARK: - Views
    
    private var fillupsDashboard: some View {
        AppropriateNavigationType {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        latestFillupInfo
                        
                        if fuelEconomyDataPoints.count >= 2 {
                            Divider()
                            
                            fuelEconomyChart
                        }  else {
                            chartHint
                                .padding(.bottom, 5)
                        }
                        
                        Group {
                            if fillups.count > 2 {
                                fuelEconomyDataPoints.count >= 2 ? Divider() : nil
                                
                                Text("Average")
                                    .badge("\(averageFuelEconomy, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                            }
                        }
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                    }
                    .padding(.vertical, 5)
                }
                .listRowSeparator(.hidden)
                
                ZStack {
                    Color.clear
                    
                    NavigationLink {
                        AllFillupsListView(vehicle: vehicle)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.arrow.circlepath")
                                .accessibilityHidden(true)
                            
                            Text("Fill-up History")
                        }
                    }
                }
            }
            .navigationTitle("Fill-ups")
            .overlay {
                if vehicle.sortedFillupsArray.isEmpty {
                    FillupsStartView(showingAddFillup: $showingAddFillup)
                }
            }
            .onAppear {
                populateFuelEconomyDataPoints()
            }
            .onChange(of: selectedDateRange) { _ in
                populateFuelEconomyDataPoints()
            }
            .onChange(of: Array(fillups)) { _ in
                populateFuelEconomyDataPoints()
                animateTrendArrow(shouldReset: true)
            }
            .sheet(isPresented: $showingAddFillup) {
                AddFillupView(vehicle: vehicle, quickFill: false)
            }
            .sheet(isPresented: $showingfuelEconomyInfo) { FuelEconomyInfoView() }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Spacer()
                        Text(vehicle.name)
                            .font(.headline)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.secondary)
                            .accessibilityLabel("Back to all vehicles")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddFillup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityLabel("Add New Fill-up")
                    }
                    // iOS 16 workaround, where button could't be clicked again after sheet was dismissed - iOS 15 and 17 work fine without this
                    .id(UUID())
                }
            }
        }
    }
    
    // Returns the numbers along the y-axis on the left side of the fuel economy chart
    private var chartYAxis: some View {
        let maxY = fuelEconomyDataPoints.max() ?? 0
        let minY = fuelEconomyDataPoints.min() ?? 0
        let midY = (maxY + minY) / 2
        
        return VStack {
            Text("\(maxY.rounded(.up), specifier: "%.1f")")
            Spacer()
            Text("\((maxY + midY) / 2, specifier: "%.1f")")
            Spacer()
            Text("\(midY, specifier: "%.1f")")
            Spacer()
            Text("\((midY + minY) / 2, specifier: "%.1f")")
            Spacer()
            Text("\(minY.rounded(.down), specifier: "%.1f")")
        }
    }
    
    // View that groups the trend arrow, fuel economy info, and headline into one element
    private var headlineGroup: some View {
        HStack {
            if fillups.count > 3 {
                trendArrow
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Latest Fill-up")
                    .font(.headline)
                
                if let latestFillup = fillups.first {
                    if latestFillup.fuelEconomy != 0 {
                        HStack(spacing: 3) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\((latestFillup.fuelEconomy), specifier: "%.1f")")
                                    .font(.title.bold())
                                Text("\(settings.fuelEconomyUnit.rawValue)")
                                    .bold()
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    } else {
                        if fillups.count == 1 {
                            Text("First Fill")
                                .bold()
                                .foregroundStyle(Color.secondary)
                                .padding(.top, 10)
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text("Fuel Economy Unavailable")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.secondary)
                                
                                Button {
                                    showingfuelEconomyInfo = true
                                } label: {
                                    Label("Learn More", systemImage: "info.circle")
                                        .labelStyle(.iconOnly)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                }
            }
        }
    }
    
    // Displays info about the latest fill-up
    private var latestFillupInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                headlineGroup
                
                Spacer()
                
                Text(fillups.first?.date.formatted(date: .numeric, time: .omitted) ?? "-")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        // Prevents everything except the graph line from animating
        .transaction { transaction in
            transaction.animation = nil
        }
    }
    
    // Presents a line chart, with fuel economy over the time period specified in a picker (default is last 6 months)
    private var fuelEconomyChart: some View {
        VStack(alignment: .center, spacing: 15) {
            HStack {
                chartYAxis
                
                VStack {
                    Spacer()
                    LineChartView(data: fuelEconomyDataPoints, average: averageFuelEconomy)
                    Spacer()
                }
            }
            .font(.caption)
            .foregroundStyle(Color.secondary)
            .aspectRatio(2, contentMode: .fit)
            .clipShape(Rectangle())
            
            Picker("", selection: $selectedDateRange) {
                ForEach(DateRange.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // Displays a hint that explains how many full tank fill-ups remain, until the fuel economy chart will be avaialble
    private var chartHint: some View {
        ZStack {
            Color(.socketPurple)
            
            Text("Add \(fillupsRemaining) more **Full Tank** \(fillupsRemaining == Text("1") ? "fill-up" : "fill-ups") to see a graph of your fuel economy over time.")
                .padding(20)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .aspectRatio(2, contentMode: .fit)
    }
    
    // Arrow that signals to users whether their latest fill-up had better fuel economy than the previous fill-up
    private var trendArrow: some View {
        let latestFillupFuelEconomy = fillups.first?.fuelEconomy ?? 0
        let previousFillupFuelEconomy = fillups[1].fuelEconomy
        
        return ZStack {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundStyle(Color(.tertiarySystemGroupedBackground))
            
            if latestFillupFuelEconomy > previousFillupFuelEconomy {
                upArrow
            } else if latestFillupFuelEconomy < previousFillupFuelEconomy {
                downArrow
            } else {
                equalSign
            }
        }
        .font(.title.bold())
        .animation(.bouncy, value: animatingTrendArrow)
        .onAppear { animateTrendArrow(shouldReset: false) }
        .mask {
            Circle()
                .frame(width: 40, height: 40)
        }
    }
    
    // Up arrow Image
    private var upArrow: some View {
        Image(systemName: "chevron.up")
            .foregroundStyle(.green)
            .offset(y: animatingTrendArrow ? 0 : 40)
            .accessibilityLabel("Fuel economy is up since your last fill-up")
    }
    
    // Down arrow Image
    private var downArrow: some View {
        Image(systemName: "chevron.down")
            .foregroundStyle(.red)
            .offset(y: animatingTrendArrow ? 0 : -40)
            .accessibilityLabel("Fuel economy is down since your last fill-up")
    }
    
    // Equal sign Image
    private var equalSign: some View {
        Image(systemName: "equal")
            .foregroundStyle(Color.selectedColor(for: .fillupsTheme))
            .accessibilityLabel("Fuel economy is the same as your last fill-up")
    }
    
    
    // MARK: - Computed Properties
    
    // Returns text, describing how may fill-ups remain until the fuel economy chart is available
    private var fillupsRemaining: Text {
        var numberRemaining = Text("")
        
        if fuelEconomyDataPoints.count == 0 {
            numberRemaining = Text("2")
        } else if fuelEconomyDataPoints.count == 1 {
            if let latestFillup = fillups.first {
                if latestFillup.fillType != .partialFill {
                    numberRemaining = Text("1")
                } else {
                    numberRemaining = Text("2")
                }
            }
        }
        
        return numberRemaining
    }
    
    // Calculates the average fuel economy for all fill-ups logged for the given vehicle
    private var averageFuelEconomy: Double {
        var distances: [Int] = []
        var volumes: [Double] = []
        
        for fillup in fillups {
            if fillup != fillups.last && fillup.fillType != .missedFill {
                switch selectedDateRange {
                case .sixMonths:
                    if fillup.date > Calendar.current.date(byAdding: .month, value: -6, to: Date.now)! {
                        distances.append(Int(fillup.tripDistance))
                        volumes.append(fillup.volume)
                    }
                case .year:
                    if fillup.date > Calendar.current.date(byAdding: .year, value: -1, to: Date.now)! {
                        distances.append(Int(fillup.tripDistance))
                        volumes.append(fillup.volume)
                    }
                case .all:
                    distances.append(Int(fillup.tripDistance))
                    volumes.append(fillup.volume)
                }
            }
        }
        
        if settings.fuelEconomyUnit == .L100km {
            return (volumes.reduce(0, +) / Double(distances.reduce(0, +))) * 100
        } else {
            return Double(distances.reduce(0, +)) / volumes.reduce(0, +)
        }
    }
    
    
    // MARK: - Methods
    
    // Populates the fuelEconomyDataPoints array with all non-zero fuel economy values found in the fillups fetch request
    func populateFuelEconomyDataPoints() {
        var dataPoints: [Double] = []
        
        for fillup in fillups.reversed() {
            if fillup.fuelEconomy != 0 {
                switch selectedDateRange {
                case .sixMonths:
                    if fillup.date > Calendar.current.date(byAdding: .month, value: -6, to: Date.now)! {
                        dataPoints.append(fillup.fuelEconomy)
                    }
                case .year:
                    if fillup.date > Calendar.current.date(byAdding: .year, value: -1, to: Date.now)! {
                        dataPoints.append(fillup.fuelEconomy)
                    }
                case .all:
                    dataPoints.append(fillup.fuelEconomy)
                }
            }
        }

        fuelEconomyDataPoints = dataPoints
    }
    
    // Animates trendArrow into view, with option to reset to it's original position off-screen (for animation after adding new fill-up)
    func animateTrendArrow(shouldReset: Bool) {
        if shouldReset == true {
            animatingTrendArrow = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animatingTrendArrow = true
        }
    }
}

#Preview {
    FillupsDashboardView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
