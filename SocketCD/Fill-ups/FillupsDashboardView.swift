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
    @State private var showingFuelEconomyInfo = false
    @State private var animatingTrendArrow = false
    @State private var selectedDateRange: DateRange = .sixMonths
    
    var body: some View {
        ZStack {
            if vehicle.sortedFillupsArray.isEmpty {
                FillupsStartView()
            } else {
                List {
                    VStack {
                        headlineGroup
                        
                        if data.count == 0 {
                            emptyChartView
                        } else {
                            FuelEconomyChartView(data: data, averageFuelEconomy: averageFuelEconomy, selectedDateRange: $selectedDateRange)
                            
                            Picker("Date Range", selection: $selectedDateRange) {
                                ForEach(DateRange.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Divider().frame(height: 0)
                            
                            LabeledContent("Average") {
                                Text("\(averageFuelEconomy, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                            }
                            .padding(.top, 5)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    Section {
                        NavigationLink {
                            AllFillupsListView(vehicle: vehicle)
                        } label: {
                            Label("Fill-up History", systemImage: "clock.arrow.circlepath")
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
            }
        }
        .tint(settings.accentColor(for: .fillupsTheme))
        .navigationTitle("Fill-ups")
        .sheet(isPresented: $showingAddFillup) { AddEditFillupView(vehicle: vehicle) }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add Fill-up", systemImage: "plus") {
                    showingAddFillup = true
                }
            }
        }
    }
    
    
    // MARK: - Views
    
    // View that groups the trend arrow, fuel economy info, and headline into one element
    private var headlineGroup: some View {
//        HStack {
//            if fillups.count > 3 && fillups.first?.fuelEconomy(settings: settings) != 0 {
//                TrendArrowView(fillups: fillups)
//            }
            
            VStack(alignment: .leading, spacing: 0) {
                LabeledContent("Latest") {
                    guard let date = fillups.first?.date else { return Text("") }
                        
                    return Text(date.formatted(date: .numeric, time: .omitted))
                        .font(.subheadline)
                }
                .font(.headline)
                
                if let latestFillup = fillups.first {
                    let economy = latestFillup.fuelEconomy(settings: settings)
                    
                    if economy > 0 {
                        Text("\(economy, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                            .font(.title2.bold())
                    } else {
                        HStack(spacing: 3) {
                            Text("No \(settings.fuelEconomyUnit.rawValue)")
                                .font(.title2.bold())
                            
                            Button("Learn More", systemImage: "info.circle") {
                                showingFuelEconomyInfo = true
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .popover(isPresented: $showingFuelEconomyInfo) {
                                Text("Fuel economy will be calculated after your next **Full Tank** fill-up.")
                                    .font(.subheadline)
                                    .padding()
                                    .frame(width: 300)
                                    .presentationCompactAdaptation(.popover)
                            }
                        }
                    }
                }
            }
//        }
    }
    
    // Displayed when no data points exist to place on the chart
    private var emptyChartView: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
            
            Text("One more to go")
                .font(.title2.bold())
                .foregroundStyle(Color.primary)
            
            Text("Add another **Full Tank** fill-up to see your fuel economy chart.")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
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
    private var averageFuelEconomy: Double {
        guard !data.isEmpty else { return 0 }
        let total = data.map { $0.fuelEconomy(settings: settings) }.reduce(0, +)
        
        return total / Double(data.count)
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return FillupsDashboardView(vehicle: vehicle)
        .environmentObject(AppSettings())
}
