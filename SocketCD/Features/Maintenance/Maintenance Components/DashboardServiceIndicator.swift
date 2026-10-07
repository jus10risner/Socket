//
//  DashboardServiceIndicator.swift
//  SocketCD
//
//  Created by Justin Risner on 10/6/26.
//

import SwiftUI

struct DashboardServiceIndicator: View {
    @ObservedObject var vehicle: Vehicle
    @ObservedObject var service: Service

    @State private var showsStatus = false

    private let diameter: CGFloat = 50

    var body: some View {
        ZStack {
            Circle()
                .fill(displayedColor.gradient)

            Image(systemName: displayedSymbol)
                .imageScale(.large)
                .fontWeight(displayedSymbol == "exclamationmark" ? .black : .regular)
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace.upUp))
        }
        .frame(width: diameter, height: diameter)
        .dynamicTypeSize(.medium)
        .accessibilityHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.snappy) {
                    showsStatus = service.serviceStatus != .notDue
                }
            }
        }
    }

    private var displayedSymbol: String {
        guard showsStatus else {
            return "book.and.wrench.fill"
        }

        switch service.serviceStatus {
        case .notDue:
            return "book.and.wrench.fill"
        case .due:
            return "clock.fill"
        case .overDue:
            return "exclamationmark"
        }
    }

    private var displayedColor: Color {
        guard showsStatus else {
            return Color(.maintenanceTheme)
        }

        switch service.serviceStatus {
        case .notDue:
            return Color(.maintenanceTheme)
        case .due:
            return .orange
        case .overDue:
            return .red
        }
    }

}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"

    let service = Service(context: context)
    service.vehicle = vehicle

    return DashboardServiceIndicator(
        vehicle: vehicle,
        service: service
    )
}
