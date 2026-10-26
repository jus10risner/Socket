//
//  RepairsListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData
import SwiftUI

private enum RepairGrouping: String, CaseIterable, Identifiable {
    case date
    case category

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .date: "Date"
        case .category: "Category"
        }
    }

    var symbol: String {
        switch self {
        case .date: "calendar"
        case .category: "folder"
        }
    }
}

struct RepairsListView: View {
    @ObservedObject var vehicle: Vehicle
    @FetchRequest var repairs: FetchedResults<Repair>

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._repairs = FetchRequest(
            entity: Repair.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Repair.date_, ascending: false)
            ],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }

    @State private var showingAddRepair = false
    @AppStorage("repairGrouping") private var grouping: RepairGrouping = .date

    var body: some View {
        List {
            if grouping == .date {
                ForEach(repairsByYear, id: \.year) { section in
                    HistoryListSection(
                        year: section.year,
                        headerColor: AppSection.repairs.color
                    ) {
                        ForEach(section.repairs, id: \.id) { repair in
                            repairRow(repair)
                        }
                    }
                }
            } else {
                ForEach(repairsByCategory) { section in
                    Section {
                        ForEach(section.repairs, id: \.id) { repair in
                            repairRow(repair, includesYear: true)
                        }
                    } header: {
                        categoryHeader(section.title)
                    }
                    .headerProminence(.increased)
                }
            }
        }
        .sectionNavigationTitle(AppSection.repairs.title, vehicleName: vehicle.name)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .overlay {
            if repairs.isEmpty {
                ContentUnavailableView {
                    Label("No Repairs", systemImage: AppSection.repairs.symbol())
                } description: {
                    Text("Record unexpected work, such as battery replacement or engine repair.")
                }
            }
        }
        .sheet(isPresented: $showingAddRepair) {
            AddEditRepairView(vehicle: vehicle)
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Picker("Group Repairs", selection: $grouping) {
                        ForEach(RepairGrouping.allCases) { option in
                            Label(option.title, systemImage: option.symbol)
                                .tag(option)
                        }
                    }
                } label: {
                    Label("Group Repairs", systemImage: "line.3.horizontal.decrease")
                }
                .adaptiveTint()
                .accessibilityValue(grouping.title)
            }

            AdaptiveToolbarButton {
                Button("Add Repair", systemImage: "plus") {
                    showingAddRepair = true
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(AppSection.repairs.color)
            }
        }
    }

    @ViewBuilder
    private func repairRow(_ repair: Repair, includesYear: Bool = false) -> some View {
        NavigationLink {
            RepairDetailView(repair: repair)
        } label: {
            HistoryListRow(
                date: repair.date,
                includesYear: includesYear
            ) {
                VStack(alignment: .leading) {
                    Text(repair.name)
                        .font(.headline)
                    
                    Text("\(repair.odometer.formatted()) \(vehicle.distanceUnit.abbreviated)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func categoryHeader(_ category: String) -> some View {
        if category.isEmpty {
            Text("Uncategorized")
                .foregroundStyle(AppSection.repairs.color)
        } else {
            Text(category)
                .foregroundStyle(AppSection.repairs.color)
        }
    }

    var repairsByYear: [(year: Int, repairs: [Repair])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: repairs) { repair in
            calendar.component(.year, from: repair.date)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (year: $0.key, repairs: $0.value) }
    }

    private var repairsByCategory: [RepairCategorySection] {
        let grouped = Dictionary(grouping: repairs) { repair in
            repair.category?.objectID.uriRepresentation().absoluteString ?? ""
        }

        return grouped.map { key, repairs in
            RepairCategorySection(
                id: key,
                title: repairs.first?.category?.name ?? "",
                repairs: repairs.sorted { $0.date > $1.date }
            )
        }
        .sorted { first, second in
            if first.title.isEmpty { return false }
            if second.title.isEmpty { return true }
            return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
        }
    }
}

private struct RepairCategorySection: Identifiable {
    let id: String
    let title: String
    let repairs: [Repair]
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345

    return RepairsListView(vehicle: vehicle)
}
