
//
//  VehicleNavigationTitle.swift
//  SocketCD
//

import SwiftUI

private struct VehicleNavigationTitleModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let title: LocalizedStringKey
    let vehicleName: String

    private var legacyTitleMaxWidth: CGFloat {
        horizontalSizeClass == .compact ? 170 : 280
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .navigationTitle(title)
                .navigationSubtitle(vehicleName)
                .navigationBarTitleDisplayMode(.inline)
        } else {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        LegacyVehicleNavigationTitle(
                            title: title,
                            vehicleName: vehicleName,
                            maxWidth: legacyTitleMaxWidth
                        )
                    }
                }
        }
    }
}

private struct LegacyVehicleNavigationTitle: View {
    let title: LocalizedStringKey
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
    func vehicleNavigationTitle(
        _ title: LocalizedStringKey,
        vehicleName: String
    ) -> some View {
        modifier(
            VehicleNavigationTitleModifier(
                title: title,
                vehicleName: vehicleName
            )
        )
    }
}
