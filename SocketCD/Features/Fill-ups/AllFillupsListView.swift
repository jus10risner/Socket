//
//  AllFillupsListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import CoreData
import SwiftUI

struct AllFillupsListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vehicle: Vehicle
    
    @FetchRequest private var fillups: FetchedResults<Fillup>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._fillups = FetchRequest(
            entity: Fillup.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Fillup.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    var body: some View {
        List {
            ForEach(fillupsByYear, id: \.year) { section in
                HistoryListSection(year: section.year, headerColor: AppSection.fillups.color) {
                    ForEach(section.fillups) { fillup in
                        NavigationLink {
                            FillupDetailView(fillup: fillup)
                        } label: {
                            FillupHistoryRow(
                                fillup: fillup,
                                isFirstFullTank: fillup == firstFullTank
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Fill-up History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if fillups.isEmpty { dismiss() }  }
    }

    private var fillupsByYear: [(year: Int, fillups: [Fillup])] {
        let groups = Dictionary(grouping: fillups) {
            Calendar.current.component(.year, from: $0.date)
        }
        return groups.map { (year: $0.key, fillups: $0.value) }
            .sorted { $0.year > $1.year }
    }

    private var firstFullTank: Fillup? {
        fillups.last { $0.fillType == .fullTank }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return AllFillupsListView(vehicle: vehicle)
}
