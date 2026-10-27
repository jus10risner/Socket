//
//  FillupsDashboardView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData
import SwiftUI

struct FillupsDashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var vehicle: Vehicle
    @FetchRequest var fillups: FetchedResults<Fillup>

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._fillups = FetchRequest(
            entity: Fillup.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Fillup.date_, ascending: false)
            ],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }

    @State private var showingAddFillup = false
    @State private var showingLatestExplanation = false
    @State private var selectedDateRange: DateRange = .threeMonths
    @State private var chartPoints: [ChartPoint]?
    @State private var chartRefreshID = 0

    var body: some View {
        List {
            if fillups.count > 0 {
                Section {
                    fuelEconomyChart
                    
                    lifetimeAverageFooter
                } footer: {
                    if let latestUnavailableMessage {
                        Button("Where’s my latest fill-up?") {
                            showingLatestExplanation = true
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppSection.fillups.color)
                        .textCase(nil)
                        .popover(
                            isPresented: $showingLatestExplanation
                        ) {
                            PopoverContent(
                                text: latestUnavailableMessage
                            )
                        }
                    }
                }
                
                Section {
                    NavigationLink {
                        AllFillupsListView(vehicle: vehicle)
                    } label: {
                        Label {
                            Text("Fill-up History")
                        } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(AppSection.fillups.color)
                        }
                    }
                }
            }
        }
        .sectionNavigationTitle(AppSection.fillups.title, vehicleName: vehicle.name)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .overlay {
            if fillups.isEmpty {
                ContentUnavailableView {
                    Label("No Fill-ups", systemImage: AppSection.fillups.symbol())
                } description: {
                    Text("Log each time you refuel to see fuel economy trends over time.")
                }
            }
        }
        .task(id: chartDataRevision) {
            await updateChartData()
        }
        .sheet(
            isPresented: $showingAddFillup,
            onDismiss: { chartRefreshID += 1 }
        ) {
            AddEditFillupView(vehicle: vehicle)
        }
        .toolbar {
            AdaptiveToolbarButton {
                Button("Add Fill-up", systemImage: "plus") {
                    showingAddFillup = true
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(AppSection.fillups.color)
            }
        }
    }

    // MARK: - Chart Data

    private var fuelEconomyChart: some View {
        VStack(spacing: 15) {
            if let chartPoints, chartPoints.isEmpty {
                FuelEconomySetupView(state: fuelEconomySetupState)
            } else {
                Picker("Date Range", selection: $selectedDateRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue)
                            .tag(range)
                            .accessibilityLabel(range.accessibilityLabel)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(chartPoints == nil)
                .accessibilityHint("Selects the range for fuel economy data.")
                
                FuelEconomyChartView(
                    data: chartPoints ?? [],
                    fuelEconomyUnit: vehicle.fuelEconomyUnit,
                    selectedDateRange: $selectedDateRange,
                    initialLatestDate: fillups.first?.date ?? .now
                )
            }
        }
        .padding(15)
        .listRowInsets(EdgeInsets())
    }

    @ViewBuilder
    private var lifetimeAverageFooter: some View {
        if let chartPoints,
            let average = ChartPoint.aggregateFuelEconomy(
                from: chartPoints,
                unit: vehicle.fuelEconomyUnit
            )
        {
            LabeledContent("Lifetime Average") {
                Text("\(average.formatted(.number.precision(.fractionLength(1)))) \(vehicle.fuelEconomyUnit.displayName)")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Lifetime average fuel economy, \(average.formatted(.number.precision(.fractionLength(1)))) \(vehicle.fuelEconomyUnit.fullName)"
            )
        }
    }

    private var latestUnavailableMessage: String? {
        guard let latestFillup = fillups.first,
            let latestChartPoint = chartPoints?.last,
            latestChartPoint.id != latestFillup.objectID
        else {
            return nil
        }

        return switch latestFillup.fillType {
        case .partialFill:
            "The latest fill-up was a Partial Fill, so fuel economy wasn’t calculated. Fuel economy will be calculated again after your next Full Tank fill-up."
        case .missedFill:
            "The latest fill-up was marked as Missed, so fuel economy wasn’t calculated. Fuel economy will be calculated again after your next Full Tank fill-up."
        case .fullTank:
            "Fuel economy wasn’t available for the latest fill-up."
        }
    }

    private var fuelEconomySetupState: FuelEconomySetupState {
        let hasBaseline = fillups.contains {
            $0.fillType == .fullTank || $0.fillType == .missedFill
        }

        return hasBaseline ? .needsFullTank : .needsBaseline
    }

    // Changes when chart-relevant Core Data values or the display unit change.
    private var chartDataRevision: Int {
        var hasher = Hasher()
        hasher.combine(chartRefreshID)
        hasher.combine(vehicle.fuelEconomyUnit.rawValue)

        for fillup in fillups {
            hasher.combine(fillup.objectID)
            hasher.combine(fillup.chartDataRevision)
        }

        return hasher.finalize()
    }

    private func updateChartData() async {
        guard
            let coordinator = vehicle.managedObjectContext?
                .persistentStoreCoordinator
        else {
            chartPoints = []
            return
        }

        let vehicleID = vehicle.objectID
        let unit = vehicle.fuelEconomyUnit
        let context = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        do {
            let points = try await context.perform {
                guard
                    let backgroundVehicle = try context.existingObject(
                        with: vehicleID
                    ) as? Vehicle
                else {
                    return [ChartPoint]()
                }
    
                let request = Fillup.fetchRequest()
                request.predicate = NSPredicate(
                    format: "vehicle == %@",
                    backgroundVehicle
                )
                request.sortDescriptors = [
                    NSSortDescriptor(
                        keyPath: \Fillup.date_,
                        ascending: true
                    )
                ]
                request.fetchBatchSize = 256
                request.returnsObjectsAsFaults = false
    
                let fillups = try context.fetch(request)
                return ChartPoint.make(from: fillups, unit: unit)
            }
            try Task.checkCancellation()
            chartPoints = points
        } catch is CancellationError {
            return
        } catch {
            chartPoints = []
            print(
                "⚠️ Failed to prepare fuel-economy chart data: \(error.localizedDescription)"
            )
        }
    }

}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345

    return FillupsDashboardView(vehicle: vehicle)
}
