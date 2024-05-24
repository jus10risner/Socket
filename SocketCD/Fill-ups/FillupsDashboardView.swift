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
    
    var body: some View {
        fillupsDashboard
    }
    
    
    // MARK: - Views
    
    private var fillupsDashboard: some View {
        AppropriateNavigationType {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Latest Fill-up")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(fillups.first?.date.formatted(date: .numeric, time: .omitted) ?? "-")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            if let latestFillup = fillups.first {
                                if latestFillup.fuelEconomy != 0 {
                                    HStack(spacing: 3) {
                                        fillups.count < 3 ? nil : trendArrow
                                        
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
                                    }
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                        // Prevents everything except the graph line from animating
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                        
                        fuelEconomyDataPoints.count >= 2 ? Divider() : nil
                        
                        HStack {
                            if fuelEconomyDataPoints.count >= 2 {
                                chartYAxis
                                
                                VStack {
                                    Spacer()
                                    LineChartView(data: fuelEconomyDataPoints, average: averageFuelEconomy)
                                    Spacer()
                                }
                            } else {
                                ZStack {
                                    Color(.socketPurple)
                                    
                                    Text("Add \(fillupsRemaining) more **Full Tank** \(fillupsRemaining == Text("1") ? "fill-up" : "fill-ups") to see a graph of your fuel economy over time.")
                                        .padding(20)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .aspectRatio(2, contentMode: .fit)
                        
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
            .overlay {
                if vehicle.sortedFillupsArray.isEmpty {
                    FillupsStartView(showingAddFillup: $showingAddFillup)
                }
            }
            .onAppear {
                populateFuelEconomyDataPoints()
            }
            .navigationTitle("Fill-ups")
            .onChange(of: vehicle.sortedFillupsArray) { _ in
                populateFuelEconomyDataPoints()
                animateTrendArrow(shouldReset: true)
                vehicle.determineIfNotificationDue()
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
//        .modifier(ConditionalSearchableViewModifier(isSearchable: sortedRepairs.count >= 7, searchString: $searchText))
//        .searchable(text: $searchText)
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
    
    // Arrow that signals to users whether their latest fill-up had better fuel economy than the previous fill-up
    private var trendArrow: some View {
        let latestFillupFuelEconomy = fillups.first?.fuelEconomy ?? 0
        let previousFillupFuelEconomy = fillups[1].fuelEconomy
        
        return ZStack {
            Circle()
                .frame(width: 35, height: 35)
                .foregroundStyle(Color(.tertiarySystemGroupedBackground))
            
            if latestFillupFuelEconomy > previousFillupFuelEconomy {
                upArrow
            } else if latestFillupFuelEconomy < previousFillupFuelEconomy {
                downArrow
            } else {
                equalSign
            }
        }
        .font(.title2.bold())
        .animation(.bouncy, value: animatingTrendArrow)
        .onAppear { animateTrendArrow(shouldReset: false) }
        .mask {
            Circle()
                .frame(width: 35, height: 35)
        }
    }
    
    // Up arrow Image
    private var upArrow: some View {
        Image(systemName: "chevron.up")
            .foregroundStyle(.green)
            .offset(y: animatingTrendArrow ? 0 : 25)
//            .animation(.spring, value: animatingTrendArrow)
            .accessibilityLabel("Fuel economy is up since your last fill-up")
    }
    
    // Down arrow Image
    private var downArrow: some View {
        Image(systemName: "chevron.down")
            .foregroundStyle(.red)
            .offset(y: animatingTrendArrow ? 0 : -25)
//            .animation(.spring, value: animatingTrendArrow)
            .accessibilityLabel("Fuel economy is down since your last fill-up")
    }
    
    // Equal sign Image
    private var equalSign: some View {
        Image(systemName: "equal")
            .foregroundStyle(Color.selectedColor(for: .fillupsTheme))
            .accessibilityLabel("Fuel economy is the same as your last fill-up")
    }
    
    
    // MARK: - Computed Properties
    
    // Provides the points that the line chart connects
//    private var fuelEconomyDataPoints: [Double] {
//        var dataPoints: [Double] = []
//        
//        for fillup in fillups.reversed() {
//            if fillup.fuelEconomy != 0 {
//                dataPoints.append(fillup.fuelEconomy)
//            }
//        }
//        
//        return dataPoints
//        
////        return [0, 21.2, 15.2, 23.5, 23.7, 21.4, 21.6, 27.6, 25.7, 26.0, 25.1, 23.5, 19.9, 24.6, 17.0, 26.3, 23.7, 18.0, 22.5, 18.8, 25.3, 19.6, 23.2, 28.8, 21.1, 27.8, 19.2, 23.7, 23.4, 24.9, 24.3, 22.9, 23.4, 23.2, 26.8, 26.0, 26.4, 23.6, 24.5, 22.2, 27.7, 23.3, 26.2, 25.7, 27.8, 23.1, 25.9, 23.1, 23.0, 27.0, 25.4, 26.8, 24.8]
//    }
    
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
                distances.append(Int(fillup.tripDistance))
                volumes.append(fillup.volume)
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
                dataPoints.append(fillup.fuelEconomy)
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
