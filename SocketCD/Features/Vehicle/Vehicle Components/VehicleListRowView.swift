//
//  VehicleListRowView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/24/24.
//

import CoreData
import SwiftUI

struct VehicleListRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var vehicle: Vehicle

    let settings = AppSettingsStore.shared
    let isSelected: Bool
    let usesExpandedNavigation: Bool

    @FetchRequest private var services: FetchedResults<Service>

    init(
        vehicle: Vehicle,
        isSelected: Bool,
        usesExpandedNavigation: Bool
    ) {
        self.vehicle = vehicle
        self.isSelected = isSelected
        self.usesExpandedNavigation = usesExpandedNavigation
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }

    var body: some View {
        ZStack {
            if settings.vehicleListShouldBeCompact {
                CompactVehicleListRow(
                    vehicle: vehicle,
                    distanceUnit: settings.distanceUnit.abbreviated,
                    serviceCounts: serviceCounts
                )
            } else {
                RegularVehicleListRow(
                    vehicle: vehicle,
                    distanceUnit: settings.distanceUnit.abbreviated,
                    serviceCounts: serviceCounts
                )
            }
        }
        .background {
            RoundedRectangle.adaptive
                .fill(Color(.tertiarySystemBackground))
                .strokeBorder(
                    Color.secondary.opacity(0.5),
                    lineWidth: borderWidth
                )
        }
        .containerShape(RoundedRectangle.adaptive)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(serviceCounts.hasRequiredService ? "Service Due" : "")
        .accessibilityAddTraits(.isButton)
    }

    private var serviceCounts: VehicleServiceCounts {
        services.reduce(into: VehicleServiceCounts()) { counts, service in
            switch service.serviceStatus {
            case .due:
                counts.due += 1
            case .overDue:
                counts.overdue += 1
            case .notDue:
                break
            }
        }
    }

    private var borderWidth: CGFloat {
        usesExpandedNavigation && isSelected ? 2 : colorScheme == .dark ? 0 : 0.5
    }

    private var accessibilityLabel: String {
        var components = [
            vehicle.name,
            "\(vehicle.odometer) \(settings.distanceUnit)"
        ]

        if serviceCounts.due > 0 {
            components.append("\(serviceCounts.due) due")
        }

        if serviceCounts.overdue > 0 {
            components.append("\(serviceCounts.overdue) overdue")
        }

        return components.joined(separator: ", ")
    }
}

private struct RegularVehicleListRow: View {
    private let horizontalLayoutMinimumWidth: CGFloat = 560
    private let horizontalImageWidth: CGFloat = 400

    @ObservedObject var vehicle: Vehicle
    let distanceUnit: String
    let serviceCounts: VehicleServiceCounts

    @State private var usesHorizontalLayout = false

    var body: some View {
        let layout = usesHorizontalLayout
            ? AnyLayout(HStackLayout(alignment: .center, spacing: 12))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 10))

        layout {
            VehicleListRowImage(vehicle: vehicle)
                .aspectRatio(2, contentMode: .fit)
                .frame(maxWidth: usesHorizontalLayout ? horizontalImageWidth : .infinity)
                .clipShape(ContainerRelativeShape())
                .overlay {
                    ContainerRelativeShape()
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 0.25)
                }

            VehicleListRowDetails(
                vehicleName: vehicle.name,
                odometer: vehicle.odometer,
                distanceUnit: distanceUnit,
                serviceCounts: serviceCounts,
                nameFont: .headline
            )
            .padding(.horizontal, usesHorizontalLayout ? 8 : 11)
            .padding(.vertical, usesHorizontalLayout ? 0 : 5)
        }
        .padding(5)
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width >= horizontalLayoutMinimumWidth
        } action: { usesHorizontalLayout in
            self.usesHorizontalLayout = usesHorizontalLayout
        }
        .animation(.smooth(duration: 0.3), value: usesHorizontalLayout)
    }
}

private struct CompactVehicleListRow: View {
    @ObservedObject var vehicle: Vehicle
    let distanceUnit: String
    let serviceCounts: VehicleServiceCounts

    var body: some View {
        CompactVehicleRowLayout(spacing: 10) {
            VehicleListRowImage(vehicle: vehicle, symbolSize: 35)
                .frame(width: 100, height: 75)
                .aspectRatio(1.5, contentMode: .fit)
                .clipShape(ContainerRelativeShape())
                .overlay {
                    ContainerRelativeShape()
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 0.25)
                }

            VehicleListRowDetails(
                vehicleName: vehicle.name,
                odometer: vehicle.odometer,
                distanceUnit: distanceUnit,
                serviceCounts: serviceCounts,
                nameFont: .subheadline.bold()
            )
        }
        .padding(.leading, 5)
        .padding(.vertical, 5)
        .padding(.trailing, 12)
    }
}

private struct CompactVehicleRowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard subviews.count == 2 else { return .zero }

        let imageSize = subviews[0].sizeThatFits(.unspecified)
        let proposedWidth = proposal.width ?? imageSize.width + spacing + subviews[1].sizeThatFits(.unspecified).width
        let detailsWidth = max(0, proposedWidth - imageSize.width - spacing)
        let detailsSize = subviews[1].sizeThatFits(
            ProposedViewSize(width: detailsWidth, height: proposal.height)
        )

        return CGSize(
            width: proposedWidth,
            height: max(imageSize.height, detailsSize.height)
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard subviews.count == 2 else { return }

        let imageSize = subviews[0].sizeThatFits(.unspecified)
        let detailsWidth = max(0, bounds.width - imageSize.width - spacing)
        let detailsProposal = ProposedViewSize(width: detailsWidth, height: proposal.height)
        let detailsSize = subviews[1].sizeThatFits(detailsProposal)
        let detailsY = detailsSize.height <= imageSize.height
            ? bounds.minY + (imageSize.height - detailsSize.height) / 2
            : bounds.minY

        subviews[0].place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(imageSize)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.minX + imageSize.width + spacing, y: detailsY),
            anchor: .topLeading,
            proposal: detailsProposal
        )
    }
}

private struct VehicleListRowImage: View {
    @ObservedObject var vehicle: Vehicle
    var symbolSize: CGFloat = 70

    var body: some View {
        ZStack {
            if let carPhoto = vehicle.photo {
                VehicleImageView(carPhoto: carPhoto)
            } else {
                VehicleImageView(
                    backgroundColor: vehicle.backgroundColor,
                    symbolSize: symbolSize
                )
            }
        }
    }
}

private struct VehicleListRowDetails: View {
    let vehicleName: String
    let odometer: Int
    let distanceUnit: String
    let serviceCounts: VehicleServiceCounts
    let nameFont: Font

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 10) {
                identity

                VehicleServiceStatusIndicators(serviceCounts: serviceCounts)
                    .fixedSize(horizontal: true, vertical: false)
            }

            VStack(alignment: .leading, spacing: 6) {
                identity
                VehicleServiceStatusIndicators(serviceCounts: serviceCounts)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(vehicleName)
                .font(nameFont)
                .multilineTextAlignment(.leading)

            Text("\(odometer) \(distanceUnit)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VehicleServiceStatusIndicators: View {
    let serviceCounts: VehicleServiceCounts

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                indicators
            }

            VStack(alignment: .leading, spacing: 4) {
                indicators
            }
        }
    }

    @ViewBuilder
    private var indicators: some View {
        if serviceCounts.overdue > 0 {
            VehicleServiceStatusIndicator(
                count: serviceCounts.overdue,
                title: "Overdue",
                color: .red
            )
        }

        if serviceCounts.due > 0 {
            VehicleServiceStatusIndicator(
                count: serviceCounts.due,
                title: "Due",
                color: .orange
            )
        }
    }
}

private struct VehicleServiceStatusIndicator: View {
    let count: Int
    let title: LocalizedStringResource
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(count, format: .number)
                .monospacedDigit()

            Text(title)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(title)")
    }
}

private struct VehicleServiceCounts {
    var due = 0
    var overdue = 0

    var hasRequiredService: Bool {
        due > 0 || overdue > 0
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345

    return VehicleListRowView(
        vehicle: vehicle,
        isSelected: true,
        usesExpandedNavigation: true
    )
}
