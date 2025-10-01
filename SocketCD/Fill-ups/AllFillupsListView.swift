//
//  AllFillupsListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AllFillupsListView: View {
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
    
    var body: some View {
        List {
            ForEach(fillups) { fillup in
                NavigationLink {
                    FillupDetailView(fillup: fillup)
                } label: {
                    LabeledContent {
                        Text(fillup.date.formatted(date: .numeric, time: .omitted))
                    } label: {
                        switch fillup.fillType {
                        case .partialFill:
                            listRowLabel(symbol: "circle.bottomhalf.filled", text: "Partial Fill")
                            
                        case .missedFill:
                            listRowLabel(symbol: "circle.fill", text: "Full Tank (Reset)")
                            
                        case .fullTank:
                            if fillup == fillups.last(where: { $0.fillType == .fullTank }) {
                                listRowLabel(symbol: "circle.fill", text: "First Full Tank")
                            } else {
                                Text("\(fillup.fuelEconomy(settings: settings), specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Fill-up History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if fillups.isEmpty { dismiss() }  }
    }
    
    
    // MARK: - Views
    
    private func listRowLabel(symbol: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
            
            Text(text)
        }
        .accessibilityLabel(text)
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return AllFillupsListView(vehicle: vehicle)
        .environmentObject(AppSettings())
}
