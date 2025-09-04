//
//  VehicleListRowView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/24/24.
//

import SwiftUI

struct VehicleListRowView: View {
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var settings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var vehicle: Vehicle
    
    @FetchRequest var services: FetchedResults<Service>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var isAnimating = false
    
    @State private var quickFillupVehicle: Vehicle?
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            sidebarRowView
        } else {
            cardView
        }
    }
    
    private var cardView: some View {
        VStack(spacing: 10) {
            vehicleImage
                .aspectRatio(2, contentMode: .fit)
                .clipShape(ContainerRelativeShape())
                .overlay(
                    ContainerRelativeShape()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(vehicle.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    
                    Text("\(vehicle.odometer) \(settings.distanceUnit.abbreviated)")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                if serviceDue == true {
                    alternateMaintenanceAlert
                }
            }
            .padding(.horizontal)
        }
        .padding([.horizontal, .top], 5)
        .padding(.bottom, 10)
        .background {
            RoundedRectangle.adaptive
                .colorSchemeBackground(colorScheme: colorScheme)
                .shadow(color: .secondary.opacity(0.4), radius: 2)
        }
        .containerShape(RoundedRectangle.adaptive)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3))
    }
    
    private var sidebarRowView: some View {
        HStack(spacing: 8) {
            vehicleImage
                .aspectRatio(1.5, contentMode: .fit)
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(vehicle.name)
                    .font(.body)
                    .lineLimit(1)
                
                Text("\(vehicle.odometer) \(settings.distanceUnit.abbreviated)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if serviceDue {
                alternateMaintenanceAlert
            }
        }
    }
    
    
    // MARK: - Views
    
    var vehicleImage: some View {
        Group {
            if let carPhoto = vehicle.photo {
                VehicleImageView(carPhoto: carPhoto)
            } else {
                VehicleImageView(backgroundColor: vehicle.backgroundColor)
            }
        }
    }
    
    private var alternateMaintenanceAlert: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .symbolEffect(.bounce, value: isAnimating)
            .symbolRenderingMode(.multicolor)
            .font(.title3)
            .foregroundStyle(.red)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    isAnimating = true
                }
            }
    }
    
    // Animated symbol, to draw user attention to a vehicle that is due for service
//    var maintenanceAlert: some View {
//        Image(systemName: "exclamationmark.circle.fill")
//            .symbolRenderingMode(.multicolor)
//            .font(.title3)
//            .foregroundStyle(.red)
//            .overlay(
//                Circle()
//                    .stroke(.red)
//                    .scaleEffect(isAnimating ? 2 : 0.8)
//                    .opacity(2 - (isAnimating ? 2 : 0))
//                    .animation(isAnimating ? .easeInOut(duration: 1.5)
//                        .delay(2)
//                        .repeatForever(autoreverses: false) : .easeOut(duration: 0), value: isAnimating)
//            )
//            .onAppear { animateMaintenanceAlert() }
//            .accessibilityLabel("Maintenance Due")
//    }
    
    
    // MARK: - Methods
    
    // Starts or restarts animation of the maintenanceAlert component
//    func animateMaintenanceAlert() {
////        if isAnimating {
////            isAnimating = false
////        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            isAnimating = true
//        }
//    }
    
    
    // MARK: - Computed Properties
    
    // Determines whether to show maintenanceAlert for the given vehicle
    var serviceDue: Bool {
        return services.contains(where: { $0.serviceStatus == .due || $0.serviceStatus == .overDue })
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleListRowView(vehicle: vehicle)
        .environmentObject(AppSettings())
}
