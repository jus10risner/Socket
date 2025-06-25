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
        allFillupsList
    }
    
    
    // MARK: - Views
    
    var allFillupsList: some View {
        List {
            ForEach(fillups, id: \.id) { fillup in
                NavigationLink {
                    FillupDetailView(vehicle: vehicle, fillup: fillup)
                } label: {
                    LabeledContent {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            if fillup.fillType == .partialFill {
                                Image(systemName: "circle.bottomhalf.filled")
                                    .accessibilityHidden(true)
                                Text("Partial Fill")
                            } else {
                                if fillup == vehicle.sortedFillupsArray.last {
                                    Image(systemName: "fuelpump.circle")
                                        .accessibilityHidden(true)
                                    Text("First Fill")
                                } else if fillup.fuelEconomy == 0 && fillup.fillType != .partialFill {
                                    Image(systemName: "circle.fill")
                                        .accessibilityHidden(true)
                                    Text("Full Tank")
                                } else {
                                    Text("\(fillup.fuelEconomy, specifier: "%.1f")")
                                        .font(.headline)
                                    Text(settings.fuelEconomyUnit.rawValue)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                    } label: {
                        Text(fillup.date.formatted(date: .numeric, time: .omitted))
                    }

                    
//                    HStack {
//                        HStack(alignment: .firstTextBaseline, spacing: 3) {
//                            if fillup.fillType == .partialFill {
//                                Image(systemName: "circle.bottomhalf.filled")
//                                    .accessibilityHidden(true)
//                                Text("Partial Fill")
//                            } else {
//                                if fillup == vehicle.sortedFillupsArray.last {
//                                    Image(systemName: "fuelpump.circle")
//                                        .accessibilityHidden(true)
//                                    Text("First Fill")
//                                } else if fillup.fuelEconomy == 0 && fillup.fillType != .partialFill {
//                                    Image(systemName: "circle.fill")
//                                        .accessibilityHidden(true)
//                                    Text("Full Tank")
//                                } else {
//                                    Text("\(fillup.fuelEconomy, specifier: "%.1f")")
//                                        .font(.headline)
//                                    Text(settings.fuelEconomyUnit.rawValue)
//                                        .foregroundStyle(Color.secondary)
//                                }
//                            }
//                        }
//                        
//                        Spacer()
//                        
//                        Text(fillup.date.formatted(date: .numeric, time: .omitted))
//                            .foregroundStyle(Color.secondary)
//                    }
//                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("Fill-up History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if fillups.isEmpty { dismiss() }  }
    }
}

#Preview {
    AllFillupsListView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
