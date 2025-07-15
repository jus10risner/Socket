//
//  ServiceIndicatorView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/11/25.
//

import SwiftUI

struct ServiceIndicatorView: View {
    @EnvironmentObject var settings: AppSettings
    let vehicle: Vehicle
    @ObservedObject var service: Service
    
    @State private var remainingValue: CGFloat = 0.0
    
    var body: some View {
        Circle()
            .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
            .frame(width: 30)
            .overlay {
                switch service.serviceStatus {
                case .overDue:
                    ZStack {
                        Circle()
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        
                        Image(systemName: "exclamationmark")
                            .font(.title3.bold())
                            .foregroundStyle(Color.red)
                            .symbolEffect(.bounce, value: remainingValue)
                    }
                default:
                    Circle()
                        .trim(from: remainingValue, to: 1.0)
                        .stroke(service.indicatorColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: remainingValue)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    remainingValue = 1.0 - progress
                    
                }
            }
    }
    
    // Calculates progress toward next maintenance service
    private var progress: CGFloat {
        var odometerProgress: CGFloat = 0
        var timeProgress: CGFloat = 0
        
        if let odometerDue = service.odometerDue {
            let milesLeft = CGFloat(odometerDue - vehicle.odometer)
            odometerProgress = max(0, milesLeft / CGFloat(service.distanceInterval))
        }
        
        if let dateDue = service.dateDue {
            let daysLeft = CGFloat(Calendar.current.dateComponents([.day], from: Date.now, to: dateDue).day ?? 0)
            var totalDays: CGFloat
            
            if service.monthsInterval == true {
                totalDays = CGFloat(service.timeInterval * 30)
            } else {
                totalDays = CGFloat(service.timeInterval * 365)
            }
            
            timeProgress = max(0, daysLeft / totalDays)
        }
        
        // Returns the greater of odomterProgress or timeProgress, or 1, if service is overdue
        return min(1, max(odometerProgress, timeProgress))
    }
}

#Preview {
    let context = DataController.shared.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    
    let service = Service(context: context)
    service.vehicle = vehicle
    
    return ServiceIndicatorView(vehicle: vehicle, service: service)
        .environmentObject(AppSettings())
}
