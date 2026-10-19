
//
//  SectionNavigationTitle.swift
//  SocketCD
//

import SwiftUI

private struct SectionNavigationTitleModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let title: LocalizedStringResource
    let vehicleName: String

    private var legacyTitleMaxWidth: CGFloat {
        horizontalSizeClass == .compact ? 170 : 280
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .navigationTitle(Text(title))
                .navigationSubtitle(vehicleName)
                .navigationBarTitleDisplayMode(.inline)
        } else {
            content
                .navigationTitle(Text(title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        LegacySectionNavigationTitle(
                            title: title,
                            vehicleName: vehicleName,
                            maxWidth: legacyTitleMaxWidth
                        )
                    }
                }
        }
    }
}

private struct LegacySectionNavigationTitle: View {
    let title: LocalizedStringResource
    let vehicleName: String
    let maxWidth: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text(vehicleName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .allowsTightening(true)
                .truncationMode(.tail)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: maxWidth)
        .accessibilityElement(children: .combine)
    }
}

extension View {
    func sectionNavigationTitle(
        _ title: LocalizedStringResource,
        vehicleName: String
    ) -> some View {
        modifier(
            SectionNavigationTitleModifier(
                title: title,
                vehicleName: vehicleName
            )
        )
    }
}
