//
//  ServiceIndicatorView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/11/25.
//

import SwiftUI

struct ServiceIndicatorView: View {
    @ObservedObject var vehicle: Vehicle
    @ObservedObject var service: Service
    
    let diameter: CGFloat = 35
    
    @State private var remainingValue = 1.0
    
    var body: some View {
        Gauge(value: remainingValue, in: 0...1) {
            Text("Service interval remaining")
        } currentValueLabel: {
            if isOverdue {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
        .gaugeStyle(
            ServiceCapacityGaugeStyle(
                tint: service.indicatorColor,
                trackTint: isOverdue ? .red : .secondary.opacity(0.25)
            )
        )
        .frame(width: diameter, height: diameter)
        .task(id: [vehicle.odometer, service.serviceRecords?.count]) {
            loadRemainingValue()
        }
        .task(id: service.sortedServiceRecordsArray.first) {
            loadRemainingValue()
        }
    }
    
    private var isOverdue: Bool {
        if case .overDue = service.serviceStatus {
            return true
        } else {
            return false
        }
    }

    private func loadRemainingValue() {
        withAnimation(.default.delay(0.5)) {
            remainingValue = max(0, min(1, service.progress(currentOdometer: vehicle.odometer)))
        }
    }
}

private struct ServiceCapacityGaugeStyle: GaugeStyle {
    let tint: Color
    let trackTint: Color

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(trackTint, lineWidth: 4)

            Circle()
                .trim(from: 0, to: configuration.value)
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            configuration.currentValueLabel
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    
    let service = Service(context: context)
    service.vehicle = vehicle
    
    return ServiceIndicatorView(vehicle: vehicle, service: service)
}
