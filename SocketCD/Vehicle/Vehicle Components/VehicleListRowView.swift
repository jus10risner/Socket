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
    let isSelected: Bool
    let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    
    @FetchRequest var services: FetchedResults<Service>
    
    init(vehicle: Vehicle, isSelected: Bool) {
        self.vehicle = vehicle
        self.isSelected = isSelected
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var isAnimating = false
    
    var body: some View {
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            sidebarRowView
//        } else {
            cardView
//        }
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
                    maintenanceAlert
                }
            }
            .padding(.horizontal)
        }
        .padding([.horizontal, .top], 5)
        .padding(.bottom, 10)
        .background {
            RoundedRectangle.adaptive
                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color(.secondarySystemGroupedBackground))
                .strokeBorder(isPad && isSelected ? Color.accentColor : Color.secondary.opacity(0.5), lineWidth: isPad && isSelected ? 2 : colorScheme == .dark ? 0 : 0.5)
        }
        .containerShape(RoundedRectangle.adaptive)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
//    private var sidebarRowView: some View {
//        HStack(spacing: 8) {
//            vehicleImage
//                .aspectRatio(1.5, contentMode: .fit)
//                .frame(height: 60)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
//                )
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(vehicle.name)
//                    .font(.body)
//                    .lineLimit(1)
//                
//                Text("\(vehicle.odometer) \(settings.distanceUnit.abbreviated)")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//            
//            Spacer()
//            
//            if serviceDue {
//                alternateMaintenanceAlert
//            }
//        }
//    }
    
    
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
    
    private var maintenanceAlert: some View {
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
    
    return VehicleListRowView(vehicle: vehicle, isSelected: true)
        .environmentObject(AppSettings())
}
