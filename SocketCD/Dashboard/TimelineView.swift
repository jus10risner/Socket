//
//  TimelineView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/16/25.
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var settings: AppSettings
    let vehicle: Vehicle
    
    var body: some View {
        List(vehicle.groupedServiceAndRepairTimeline, id: \.date) { group in
            HStack {
                VStack {
                    VStack(spacing: 0) {
                        // Month (e.g., "Oct")
                        Text(group.date.formatted(.dateTime.month(.abbreviated)))
                            .font(.subheadline)
                        // Day (e.g., "17")
                        Text(group.date.formatted(.dateTime.day()))
                            .font(.title2)
                        // Year (e.g., "2025")
                        Text(group.date.formatted(.dateTime.year()))
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    ForEach(group.entries) { item in
                        HStack(alignment: .firstTextBaseline) {
                            Group {
                                switch item.type {
                                case .repair:
                                    Image(systemName: "wrench.adjustable.fill")
                                        .foregroundStyle(settings.accentColor(for: .repairsTheme))
                                default:
                                    Image(systemName: "book.and.wrench.fill")
                                        .foregroundStyle(settings.accentColor(for: .maintenanceTheme))
                                }
                            }
                            .imageScale(.small)
                            
                            Text(item.displayName)
                        }
                    }
                    
                    Text("\(group.entries.first?.odometer.formatted() ?? "–") \(settings.distanceUnit.abbreviated)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
//            VStack(alignment: .leading, spacing: 4) {
//                HStack {
//                    Text(group.date.formatted(date: .numeric, time: .omitted))
//                        .bold()
////                        .font(.headline)
//                    Text("\(group.entries.first?.odometer.formatted() ?? "–") \(settings.distanceUnit.abbreviated)")
////                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                }
//                .font(.subheadline)
//                
//                ForEach(group.entries) { item in
//                    HStack(alignment: .firstTextBaseline) {
//                        Group {
//                            switch item.type {
//                            case .repair:
//                                Image(systemName: "wrench.adjustable.fill")
//                                    .foregroundStyle(settings.accentColor(for: .repairsTheme))
//                            default:
//                                Image(systemName: "book.and.wrench.fill")
//                                    .foregroundStyle(settings.accentColor(for: .maintenanceTheme))
//                            }
//                        }
//                        .imageScale(.small)
////                        Text("•")
////                            .padding(.trailing, 2)
//                        Text(item.displayName)
//                    }
//                }
//            }
            .padding(.vertical, 4)
        }
        .listRowSpacing(5)
        .navigationTitle("Timeline")
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return TimelineView(vehicle: vehicle)
        .environmentObject(AppSettings())
}
