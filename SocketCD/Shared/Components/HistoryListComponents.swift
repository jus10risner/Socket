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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let date: Date
    let includesYear: Bool
    @ViewBuilder let content: Content

    init(
        date: Date,
        includesYear: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.date = date
        self.includesYear = includesYear
        self.content = content()
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    HistoryListMetadata(date: date, includesYear: includesYear, isInline: true)
                    content
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(spacing: 12) {
                    HistoryListMetadata(date: date, includesYear: includesYear)
                    Divider()
                        .accessibilityHidden(true)
                    content
                        .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}

private struct HistoryListMetadata: View {
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) private var timeZone

    let date: Date
    let includesYear: Bool

    var isInline = false

    private var dateStyle: Date.FormatStyle {
        Date.FormatStyle(locale: locale, calendar: calendar, timeZone: timeZone)
    }

    private var dayComesFirst: Bool {
        // Inspect semantic fields instead of parsing punctuation or assuming a country’s order.
        let formatted = date.formatted(dateStyle.month(.abbreviated).day(.twoDigits).attributedStyle)
        return formatted.runs.first { $0.dateField == .month || $0.dateField == .day }?.dateField == .day
    }

    var body: some View {
        Group {
            if isInline {
                Text(date, format: includesYear
                     ? dateStyle.year().month(.abbreviated).day(.twoDigits)
                     : dateStyle.month(.abbreviated).day(.twoDigits))
                    .lineLimit(1)
            } else {
                VStack(alignment: .center, spacing: 2) {
                    if dayComesFirst {
                        day
                        month
                    } else {
                        month
                        day
                    }

                    if includesYear {
                        Text(date, format: dateStyle.year())
                            .font(.caption)
                    }
                }
            }
        }
        .font(.subheadline.weight(.semibold).monospacedDigit())
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(date, format: dateStyle.year().month(.wide).day()))
    }

    private var month: some View {
        Text(date.formatted(dateStyle.month(.abbreviated)).uppercased(with: locale))
    }

    private var day: some View {
        Text(date, format: dateStyle.day(.twoDigits))
    }
}
