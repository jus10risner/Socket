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
    @State private var fuelEconomyDataPoints: [Double] = []
    
    @State private var selectedDateRange: DateRange = .sixMonths
    
    var body: some View {
        fillupsDashboard
    }
    
    
    // MARK: - Views
    
    private var fillupsDashboard: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 15) {
//                        latestFillupInfo
                    headlineGroup
                    
//                        if fuelEconomyDataPoints.count >= 2 {
//                            Divider()
//
//                            fuelEconomyChart
                        
                        FuelEconomyChartView(fillups: Array(fillups))
//                        }  else {
//                            chartHint
//                                .padding(.bottom, 5)
//                        }
                    
//                        Group {
//                            if fillups.count > 2 {
////                                fuelEconomyDataPoints.count >= 2 ? Divider() : nil
//
//                                Text("Average")
//                                    .badge("\(averageFuelEconomy, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
//                            }
//                        }
//                        .transaction { transaction in
//                            transaction.animation = nil
//                        }
                }
                .padding(.vertical)
            }
            .listRowSeparator(.hidden)
            
            NavigationLink {
                AllFillupsListView(fillups: Array(fillups))
            } label: {
                Label("Fill-up History", systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(Color.primary)
            }
        }
        .navigationTitle("Fill-ups")
        .overlay {
            if vehicle.sortedFillupsArray.isEmpty {
                FillupsStartView(showingAddFillup: $showingAddFillup)
            }
        }
        .sheet(isPresented: $showingAddFillup) {
//            AddFillupView(vehicle: vehicle, quickFill: false)
            AddEditFillupView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingFuelEconomyInfo) { FuelEconomyInfoView() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddFillup = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityLabel("Add New Fill-up")
                }
                // iOS 16 workaround, where button could't be clicked again after sheet was dismissed - iOS 15 and 17 work fine without this
//                    .id(UUID())
            }
        }
    }
    
    // View that groups the trend arrow, fuel economy info, and headline into one element
    private var headlineGroup: some View {
        HStack {
            if fillups.count > 3 && fillups.first?.fuelEconomy(settings: settings) != 0 {
//                trendArrow
                TrendArrowView(fillups: fillups)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                LabeledContent("Latest Fill-up") {
                    Text(fillups.first?.date.formatted(date: .numeric, time: .omitted) ?? "-")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .font(.headline)
                
                if let latestFillup = fillups.first {
                    if latestFillup.fuelEconomy(settings: settings) != 0 {
                        HStack(spacing: 3) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\((latestFillup.fuelEconomy(settings: settings)), specifier: "%.1f")")
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
                                    showingFuelEconomyInfo = true
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
    
//    // Displays info about the latest fill-up
//    private var latestFillupInfo: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            LabeledContent {
//                Text(fillups.first?.date.formatted(date: .numeric, time: .omitted) ?? "-")
//                    .font(.subheadline)
//                    .foregroundStyle(Color.secondary)
//            } label: {
//                headlineGroup
//            }
//            
//
//            
////            HStack(alignment: .top) {
////                headlineGroup
////                
////                Spacer()
////                
////                Text(fillups.first?.date.formatted(date: .numeric, time: .omitted) ?? "-")
////                    .font(.subheadline)
////                    .foregroundStyle(Color.secondary)
////            }
//        }
//        .accessibilityElement(children: .combine)
//        // Prevents everything except the graph line from animating
//        .transaction { transaction in
//            transaction.animation = nil
//        }
//    }
    
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
    
    
    // MARK: - Computed Properties
    
    private var fillupsRemaining: Text {
        switch fuelEconomyDataPoints.count {
        case 0:
            return Text("2")
        case 1:
            return Text(fillups.first?.fillType == .partialFill ? "2" : "1")
        default:
            return Text("")
        }
    }
}

#Preview {
    FillupsDashboardView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
