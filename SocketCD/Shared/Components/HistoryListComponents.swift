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
    @ViewBuilder let content: Content

    private let settings = AppSettingsStore.shared

    init(
        date: Date,
        odometer: Int?,
        @ViewBuilder content: () -> Content
    ) {
        self.date = date
        self.odometer = odometer
        self.content = content()
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.callout.bold())

                if let odometer {
                    Text("\(odometer.formatted()) \(settings.distanceUnit.abbreviated)")
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
