//
//  HistoryListComponents.swift
//  SocketCD
//

import SwiftUI

struct HistoryListSection<Content: View>: View {
    let year: Int
    let headerColor: Color?
    @ViewBuilder let content: Content

    init(
        year: Int,
        headerColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.year = year
        self.headerColor = headerColor
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            Text(year.formatted(.number.grouping(.never)))
                .foregroundStyle(headerColor ?? .primary)
        }
        .headerProminence(.increased)
    }
}

struct HistoryListRow<Content: View>: View {
    let date: Date
    let odometer: Int?
    let distanceUnit: DistanceUnits
    let includesYear: Bool
    @ViewBuilder let content: Content

    init(
        date: Date,
        odometer: Int?,
        distanceUnit: DistanceUnits,
        includesYear: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.date = date
        self.odometer = odometer
        self.distanceUnit = distanceUnit
        self.includesYear = includesYear
        self.content = content()
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                if includesYear {
                    Text(date.formatted(.dateTime.year()))
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                }
                
                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.callout.bold())

                if let odometer {
                    Text("\(odometer.formatted()) \(distanceUnit.abbreviated)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 65, alignment: .leading)

            Divider()

            content
        }
        .padding(.vertical, 5)
    }

}
