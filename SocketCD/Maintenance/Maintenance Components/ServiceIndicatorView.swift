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
    
    @State private var isAnimating = false
    @State private var circleProgress: CGFloat = 0.0
    
    var body: some View {
        Circle()
            .stroke(Color.secondary.opacity(0.2), lineWidth: 5)
            .frame(width: 40)
            .overlay {
                switch service.serviceStatus {
                case .overDue:
                    ZStack {
                        Circle()
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        
                        Image(systemName: "exclamationmark")
                            .font(.title3.bold())
                            .foregroundStyle(Color.red)
//                            .symbolEffect(.pulse, options: .repeat(2), value: isAnimating)
                    }
                default:
                    Circle()
                        .trim(from: circleProgress, to: 1)
                        .stroke(currentColor(for: circleProgress), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
            .animation(.easeInOut.delay(0.5), value: circleProgress)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAnimating = true
                    circleProgress = 0.8
                }
            }
    }
    
//    private var progress: CGFloat {
//        guard let odometerDue = service.odometerDue else { return 0 }
//        guard let dateDue = service.dateDue else { return 0 }
//        
//        let milesDriven = odometerDue - vehicle.odometer
//        let odometerProgress = (milesDriven / service.distanceInterval)
//        
//        let daysPassed = Calendar.current.dateComponents([.day], from: Date(), to: dateDue).day ?? 0
//        let timeProgress = (daysPassed / service.timeInterval)
//        
//        print(odometerProgress)
//        print(timeProgress)
//        
//        return CGFloat(max(odometerProgress, timeProgress))
//    }
    
    func currentColor(for value: CGFloat) -> Color {
        if value >= 0.8 {
            return .yellow
        } else {
            return .green
        }
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
