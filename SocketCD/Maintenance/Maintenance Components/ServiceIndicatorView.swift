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
    
    @State private var remainingValue: CGFloat = 0.0
    
    var body: some View {
        Circle()
            .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
            .frame(width: 30)
            .overlay {
                if service.sortedServiceRecordsArray.count > 0 {
                    switch service.serviceStatus {
                    case .overDue:
                        ZStack {
                            Circle()
                                .stroke(service.indicatorColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            
                            Image(systemName: "exclamationmark")
                                .font(.title3.bold())
                                .foregroundStyle(Color.red)
                                .symbolEffect(.pulse, options: .nonRepeating)
                        }
                    default:
                        Circle()
                            .trim(from: remainingValue, to: 1.0)
                            .stroke(service.indicatorColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5).delay(0.5), value: remainingValue)
            .task(id: [vehicle.odometer, service.serviceRecords?.count]) {
                loadRemainingValue()
            }
            .task(id: service.sortedServiceRecordsArray.first) {
                loadRemainingValue()
            }
    }
    
    private func loadRemainingValue() {
        Task {
            remainingValue = 1.0 - service.progress(currentOdometer: vehicle.odometer)
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
