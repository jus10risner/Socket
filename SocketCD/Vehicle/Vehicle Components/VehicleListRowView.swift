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
    
    var body: some View {
        VStack(spacing: 10) {
            vehicleImage
                .aspectRatio(2, contentMode: .fit)
                .clipShape(ContainerRelativeShape())
                .overlay(
                    ContainerRelativeShape()
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
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
                
                if badgeNumber != 0 {
                    Image(systemName: "\(badgeNumber).circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(Color.white, Color.red)
                        .accessibilityLabel("\(badgeNumber) services due for this vehicle.")
                }
            }
            .padding(.horizontal)
        }
        .padding([.horizontal, .top], 5)
        .padding(.bottom, 10)
        .background {
            RoundedRectangle.adaptive
                .fill(colorScheme == .dark ? Color(.tertiarySystemGroupedBackground) : Color(.secondarySystemGroupedBackground))
                .strokeBorder(isPad && isSelected ? Color.accent : Color.secondary.opacity(0.5), lineWidth: isPad && isSelected ? 2 : colorScheme == .dark ? 0 : 0.5)
        }
        .containerShape(RoundedRectangle.adaptive)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
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
    
    // MARK: - Computed Properties
    
    // Calculates the number of services that are due for the given vehicle
    var badgeNumber: Int {
        return services.filter({ $0.serviceStatus == .due || $0.serviceStatus == .overDue }).count
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
