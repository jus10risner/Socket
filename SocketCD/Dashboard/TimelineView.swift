//
//  TimelineView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/16/25.
//

import SwiftUI

struct TimelineView: View {
    @Environment(\.dismiss) var dismiss
    let settings = AppSettings.shared
    let vehicle: Vehicle
    
    var body: some View {
        NavigationStack {
            List(timelineGroupsByYear, id: \.year) { yearGroup in
                Section(header: Text(yearGroup.year.formatted(.number.grouping(.never)))) {
                    ForEach(yearGroup.groups, id: \.date) { group in
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(group.date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.callout.bold())
                                
                                if let odometer = group.entries.first?.odometer {
                                    Text("\(odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .frame(minWidth: 65, alignment: .leading)
                            
                            Divider()
                            
                            VStack(alignment: .leading) {
                                ForEach(group.entries) { item in
                                    HStack(alignment: .firstTextBaseline) {
                                        Group {
                                            switch item.type {
                                            case .repair:
                                                Image(systemName: "wrench.adjustable.fill")
                                                    .foregroundStyle(Color(.repairsTheme))
                                            default:
                                                Image(systemName: "book.and.wrench.fill")
                                                    .foregroundStyle(Color(.maintenanceTheme))
                                            }
                                        }
                                        .imageScale(.small)
                                        
                                        Text(item.displayName)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Activity Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done", systemImage: "xmark") {
                    dismiss()
                }
                .labelStyle(.adaptive)
                .adaptiveTint()
            }
        }
    }
    
    // Separates timeline by year, so records can be further grouped by year performed
    private var timelineGroupsByYear: [(year: Int, groups: [(date: Date, entries: [VehicleExportRecord])])] {
        let groups = vehicle.groupedServiceAndRepairTimeline
        let groupedByYear = Dictionary(grouping: groups) { Calendar.current.component(.year, from: $0.date) }
        return groupedByYear
            .map { (year: $0.key, groups: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.year > $1.year }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return TimelineView(vehicle: vehicle)
}
