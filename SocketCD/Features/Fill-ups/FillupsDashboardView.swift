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
                        VStack(spacing: 15) {
                            if let chartPoints {
                                if chartPoints.isEmpty {
                                    emptyChartView
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
        .navigationTitle("Fill-ups")
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

            if #available(iOS 26, *) {
                ToolbarItem(placement: .principal) {
                    Text(vehicle.name)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Chart Data

    private var latestUnavailableMessage: String? {
        guard let latestFillup = fillups.first,
              let latestChartPoint = chartPoints?.last,
              latestChartPoint.id != latestFillup.objectID
        else {
            return nil
        }

        return switch latestFillup.fillType {
        case .partialFill:
            "The latest fill-up was a partial fill, so fuel economy wasn’t calculated. Fuel economy will be calculated again after your next full tank fill-up."
        case .missedFill:
            "The latest fill-up was marked as missed, so fuel economy wasn’t calculated. Fuel economy will be calculated again after your next full tank fill-up."
        case .fullTank:
            "Fuel economy wasn’t available for the latest fill-up."
        }
    }

    /// Changes when chart-relevant Core Data values or the display unit change.
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

    // MARK: - Empty State

    private var emptyChartView: some View {
        let isFullTank = fillups.contains { $0.fillType == .fullTank }

        return VStack(spacing: 5) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(Color(.fillupsTheme))
                .frame(height: 50)
                .accessibilityHidden(true)

            Group {
                if isFullTank {
                    Text("Just one more fill-up")
                } else {
                    Text("Let’s start with a full tank")
                }
            }
            .font(.title2.bold())
            .foregroundStyle(Color.primary)

            Group {
                if isFullTank {
                    Text(
                        "Add one more **Full Tank** fill-up to see your fuel economy chart."
                    )
                } else {
                    Text(
                        "Fuel economy can only be measured between **Full Tank** fill-ups."
                    )
                }
            }
            .font(.subheadline)
            .foregroundStyle(Color.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .frame(
            minHeight: horizontalSizeClass == .regular ? 350 : 200
        )
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle.adaptive
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345

    return FillupsDashboardView(vehicle: vehicle)
}
