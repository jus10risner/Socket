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
    let lineWidth: CGFloat = 4
    var showsMaintenanceSymbol = false
    
    @State private var remainingValue: CGFloat = 0.0
    
    var body: some View {
        Circle()
            .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            .frame(width: diameter, height: diameter)
            .overlay {
                ZStack {
                    if service.sortedServiceRecordsArray.count > 0 {
                        switch service.serviceStatus {
                        case .overDue:
                            ZStack {
                                Circle()
                                    .stroke(service.indicatorColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                                
                                Image(systemName: "exclamationmark")
                                    .imageScale(.large)
                                    .bold()
                                    .padding(5)
                                    .foregroundStyle(Color.red)
                            }
                        default:
                            Circle()
                                .trim(from: remainingValue, to: 1.0)
                                .stroke(service.indicatorColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                    }

                    if showsMaintenanceSymbol && !isOverdue {
                        Image(systemName: "book.and.wrench.fill")
                            .foregroundStyle(Color(.maintenanceTheme))
                    }
                }
            }
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
        Task {
            withAnimation(.default.delay(0.5)) {
                remainingValue = 1.0 - service.progress(currentOdometer: vehicle.odometer)
            }
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
