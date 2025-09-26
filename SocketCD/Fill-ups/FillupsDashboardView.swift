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
                    Section {
                        VStack(alignment: .leading, spacing: 15) {
                            headlineGroup
                            
                            FuelEconomyChartView(fillups: Array(fillups))
                        }
                        .padding(.vertical)
                    }
                    .listRowSeparator(.hidden)
                    
                    NavigationLink {
                        AllFillupsListView(vehicle: vehicle)
                    } label: {
                        Label("Fill-up History", systemImage: "clock.arrow.circlepath")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .tint(settings.accentColor(for: .fillupsTheme))
        .navigationTitle("Fill-ups")
        .sheet(isPresented: $showingAddFillup) { AddEditFillupView(vehicle: vehicle) }
        .sheet(isPresented: $showingFuelEconomyInfo) { FuelEconomyInfoView() }
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
                LabeledContent("Latest Fill-up") {
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
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("No fuel economy to display")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            
                            Button("Learn More", systemImage: "info.circle") {
                                showingFuelEconomyInfo = true
                            }
                            .labelStyle(.iconOnly)
                        }
                    }
                }
            }
//        }
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
