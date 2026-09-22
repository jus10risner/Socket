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
    @ObservedObject private var settings = AppSettingsStore.shared

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
        ZStack {
            if fillups.isEmpty {
                EmptyFillupsView()
            } else {
                List {
                    Section {
                        fuelEconomyChart
                        
                        allTimeAverageFooter
                    } footer: {
                        if let latestUnavailableMessage {
                            Button("Where’s my latest fill-up?") {
                                showingLatestExplanation = true
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.fillupsTheme)
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
                            Label(
                                "Fill-up History",
                                systemImage: "clock.arrow.circlepath"
                            )
                            .foregroundStyle(Color.primary)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .vehicleNavigationTitle("Fill-ups", vehicleName: vehicle.name)
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
                .tint(Color.fillupsTheme)
            }
        }
    }

    // MARK: - Chart Data
    
    private var fuelEconomyChart: some View {
        VStack(spacing: 15) {
            if let chartPoints {
                Group {
                    if chartPoints.isEmpty {
                        FuelEconomySetupView(
                            state: fuelEconomySetupState
                        )
                    } else {
                        FuelEconomyChartView(
                            data: chartPoints,
                            selectedDateRange: $selectedDateRange
                        )

                        Picker("Date Range", selection: $selectedDateRange) {
                            ForEach(DateRange.allCases, id: \.self) { range in
                                Text(range.rawValue)
                                    .tag(range)
                                    .accessibilityLabel(
                                        range.accessibilityLabel
                                    )
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityHint(
                            "Selects the range for fuel economy data."
                        )
                    }
                }
            } else {
                Color(.systemGroupedBackground).opacity(0.3)
                    .frame(
                        minHeight: horizontalSizeClass == .regular
                            ? 350
                            : 200
                    )
            }
        }
        .padding(15)
        .listRowInsets(EdgeInsets())
    }

    @ViewBuilder
    private var allTimeAverageFooter: some View {
        if let chartPoints,
           let average = ChartPoint.aggregateFuelEconomy(
               from: chartPoints,
               unit: settings.fuelEconomyUnit
           ),
           let firstFillupDate = fillups.last?.date {
            LabeledContent {
                Text("\(average.formatted(.number.precision(.fractionLength(1)))) \(settings.fuelEconomyUnit.rawValue)")
                    .monospacedDigit()
            } label: {
                Text("All-time average")
                Text("\(firstFillupDate.formatted(.dateTime.month(.abbreviated).year())) – Present")
                    .font(.caption)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "All-time average fuel economy, \(average.formatted(.number.precision(.fractionLength(1)))) \(settings.fuelEconomyUnit.fullName), from \(firstFillupDate.formatted(date: .long, time: .omitted)) to present"
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
        hasher.combine(settings.fuelEconomyUnit.rawValue)

        for fillup in fillups {
            hasher.combine(fillup.objectID)
            hasher.combine(fillup.date_)
            hasher.combine(fillup.odometer_)
            hasher.combine(fillup.volume_)
            hasher.combine(fillup.fillType_)
        }

        return hasher.finalize()
    }

    private func updateChartData() async {
        guard let coordinator = vehicle.managedObjectContext?
            .persistentStoreCoordinator
        else {
            chartPoints = []
            return
        }

        let vehicleID = vehicle.objectID
        let unit = settings.fuelEconomyUnit
        let context = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        do {
            let points = try await context.perform {
                guard let backgroundVehicle = try context.existingObject(
                    with: vehicleID
                ) as? Vehicle else {
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
