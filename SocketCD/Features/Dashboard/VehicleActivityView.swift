//
//  VehicleActivityView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/21/26.
//

import CoreData
import SwiftUI

struct VehicleActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var years: [VehicleHistoryYear] = []
    @State private var hasShownHistory = false
    @State private var selectedTypes = Set(VehicleHistoryRecordType.allCases)

    let vehicle: Vehicle

    var body: some View {
        Group {
            if selectedTypes.isEmpty {
                ContentUnavailableView(
                    "No Record Types Selected",
                    systemImage: "line.3.horizontal.decrease",
                    description: Text("Choose record types from the filter menu to view vehicle history.")
                )
            } else if years.isEmpty {
                ContentUnavailableView(
                    "No Records",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("No records match the selected types.")
                )
            } else {
                VehicleHistoryTimelineList(years: years, vehicle: vehicle)
            }
        }
        .onAppear {
            refreshHistory()
        }
        .onChange(of: selectedTypes) {
            years = VehicleHistoryData.years(for: vehicle, selectedTypes: selectedTypes)
        }
        .navigationTitle("Vehicle Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
                    .buttonStyle(HistoryFilterStyle(isFiltering: isFiltering))
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            ForEach(VehicleHistoryRecordType.allCases) { type in
                Toggle(isOn: Binding(
                    get: { selectedTypes.contains(type) },
                    set: { isSelected in
                        if isSelected {
                            selectedTypes.insert(type)
                        } else if selectedTypes.count > 1 {
                            selectedTypes.remove(type)
                        }
                    }
                )) {
                    Label(type.title, systemImage: type.symbol)
                }
                .disabled(selectedTypes.count == 1 && selectedTypes.contains(type))
            }

            if VehicleHistoryRecordType.allCases.count - selectedTypes.count >= 2 {
                Divider()

                Button("Select All") {
                    selectedTypes = Set(VehicleHistoryRecordType.allCases)
                }
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease")
        }
        .menuActionDismissBehavior(.disabled)
        .accessibilityValue(filterDescription)
        .adaptiveTint()
    }

    private var isFiltering: Bool {
        selectedTypes.count != VehicleHistoryRecordType.allCases.count
    }

    private var filterDescription: Text {
        if selectedTypes.isEmpty {
            Text("No record types selected")
        } else if !isFiltering {
            Text("All record types")
        } else {
            Text(VehicleHistoryRecordType.allCases
                .filter { selectedTypes.contains($0) }
                .map { String(localized: $0.title) }
                .formatted(.list(type: .and)))
        }
    }

    private func refreshHistory() {
        // Refresh only after returning, keeping the active navigation links stable during deletion.
        years = VehicleHistoryData.years(for: vehicle, selectedTypes: selectedTypes)
        let hasEvents = !vehicle.serviceAndRepairTimeline.isEmpty || !vehicle.sortedFillupsArray.isEmpty
        if hasShownHistory && !hasEvents {
            dismiss()
        }
        hasShownHistory = hasShownHistory || hasEvents
    }
}

private struct HistoryFilterStyle: PrimitiveButtonStyle {
    let isFiltering: Bool

    func makeBody(configuration: Configuration) -> some View {
        if isFiltering {
            Button(configuration).buttonStyle(.borderedProminent)
        } else {
            Button(configuration).buttonStyle(.plain)
        }
    }
}

private enum VehicleHistoryData {
    static func years(for vehicle: Vehicle, selectedTypes: Set<VehicleHistoryRecordType>) -> [VehicleHistoryYear] {
        let records = filteredRecords(for: vehicle, selectedTypes: selectedTypes)
        let fillups = selectedTypes.contains(.fillups) ? vehicle.sortedFillupsArray : []
        let events = records.map(VehicleHistoryEvent.record) + fillups.map(VehicleHistoryEvent.fillup)
        let eventsByYear = Dictionary(grouping: events) {
            Calendar.current.component(.year, from: $0.date)
        }

        return eventsByYear.map { year, events in
            VehicleHistoryYear(
                year: year,
                events: events.sorted(by: VehicleHistoryEvent.isOrderedBefore)
            )
        }
        .sorted { $0.year > $1.year }
    }

    private static func filteredRecords(for vehicle: Vehicle, selectedTypes: Set<VehicleHistoryRecordType>) -> [VehicleExportRecord] {
        vehicle.serviceAndRepairTimeline.filter { record in
            switch record.type {
            case .serviceRecord, .serviceLog:
                selectedTypes.contains(.maintenance)
            case .repair:
                selectedTypes.contains(.repairs)
            }
        }
    }

}

private enum VehicleHistoryRecordType: String, CaseIterable, Identifiable {
    case maintenance
    case repairs
    case fillups

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .maintenance: AppSection.maintenance.title
        case .repairs: AppSection.repairs.title
        case .fillups: AppSection.fillups.title
        }
    }

    var symbol: String {
        switch self {
        case .maintenance: AppSection.maintenance.symbol()
        case .repairs: AppSection.repairs.symbol()
        case .fillups: AppSection.fillups.symbol()
        }
    }

}

private struct VehicleHistoryYear: Identifiable {
    let year: Int
    let events: [VehicleHistoryEvent]

    var id: Int { year }
}

private struct VehicleHistoryTimelineList: View {
    let years: [VehicleHistoryYear]
    let vehicle: Vehicle

    var body: some View {
        List {
            ForEach(years) { year in
                HistoryListSection(year: year.year) {
                    ForEach(year.events) { event in
                        NavigationLink {
                            VehicleHistoryEventDestination(event: event, vehicle: vehicle)
                        } label: {
                            VehicleHistoryEventRow(event: event, vehicle: vehicle)
                        }
                    }
                }
            }
        }
    }
}

private enum VehicleHistoryEvent: Identifiable {
    case record(VehicleExportRecord)
    case fillup(Fillup)

    static func isOrderedBefore(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.date != rhs.date { return lhs.date > rhs.date }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    enum ID: Hashable {
        case record(NSManagedObjectID)
        case fillup(NSManagedObjectID)
    }

    var id: ID {
        switch self {
        case .record(let record):
            switch record.type {
            case .serviceRecord(let serviceRecord): .record(serviceRecord.objectID)
            case .serviceLog(let log): .record(log.objectID)
            case .repair(let repair): .record(repair.objectID)
            }
        case .fillup(let fillup):
            .fillup(fillup.objectID)
        }
    }

    var date: Date {
        switch self {
        case .record(let record): record.date
        case .fillup(let fillup): fillup.date
        }
    }

    var odometer: Int {
        switch self {
        case .record(let record): record.odometer
        case .fillup(let fillup): fillup.odometer
        }
    }

    var title: String {
        switch self {
        case .record(let record): record.displayName
        case .fillup: String(localized: "Fill-up")
        }
    }

    var section: AppSection {
        switch self {
        case .record(let record):
            if case .repair = record.type { .repairs } else { .maintenance }
        case .fillup:
            .fillups
        }
    }
}

private struct VehicleHistoryEventRow: View {
    let event: VehicleHistoryEvent
    let vehicle: Vehicle

    private var symbol: Image {
        switch event {
        case .fillup:
            Image(systemName: "fuelpump.circle.fill")
        case .record(let record):
            if case .repair = record.type {
                Image("wrench.adjustable.circle.fill")
            } else {
                Image("book.and.wrench.circle.fill")
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            symbol
                .font(.largeTitle)
                .dynamicTypeSize(.large)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, event.section.color.gradient)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.headline)

                Text(
                    "\(event.date, format: .dateTime.month(.abbreviated).day().year()) · \(event.odometer.formatted()) \(vehicle.distanceUnit.abbreviated)"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

private struct VehicleHistoryEventDestination: View {
    let event: VehicleHistoryEvent
    let vehicle: Vehicle

    var body: some View {
        switch event {
        case .fillup(let fillup):
            FillupDetailView(fillup: fillup)
        case .record(let record):
            switch record.type {
            case .repair(let repair):
                RepairDetailView(repair: repair)
            case .serviceRecord(let serviceRecord):
                if let service = serviceRecord.service {
                    RecordDetailView(record: serviceRecord, vehicle: vehicle, service: service)
                } else {
                    unavailableRecordView
                }
            case .serviceLog(let log):
                if let serviceRecord = (log.records as? Set<ServiceRecord>)?.first,
                   let service = serviceRecord.service {
                    RecordDetailView(record: serviceRecord, vehicle: vehicle, service: service)
                } else {
                    unavailableRecordView
                }
            }
        }
    }

    private var unavailableRecordView: some View {
        ContentUnavailableView(
            "Record Unavailable",
            systemImage: "exclamationmark.triangle",
            description: Text("This history item is no longer associated with a maintenance record.")
        )
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345

    return NavigationStack {
        VehicleActivityView(vehicle: vehicle)
    }
}
