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
            ForEach(fillups) { fillup in
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
        .navigationTitle("Fill-up History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if fillups.isEmpty { dismiss() }  }
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
