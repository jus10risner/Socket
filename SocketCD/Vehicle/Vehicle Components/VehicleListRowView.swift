//
//  VehicleListRowView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/24/24.
//

import SwiftUI

struct VehicleListRowView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var vehicle: Vehicle
    let settings = AppSettings.shared
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
        if settings.vehicleListShouldBeCompact {
            compactListItem
        } else {
            regularListItem
        }
    }
    
    
    // MARK: - Views
    
    // Standard vehicle card with large image and vertical layout
    private var regularListItem: some View {
        VStack(spacing: 10) {
            vehicleImage
                .aspectRatio(2, contentMode: .fit)
                .clipShape(ContainerRelativeShape())
                .overlay(
                    ContainerRelativeShape()
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 0.25)
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(vehicle.name)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    Text("\(vehicle.odometer) \(settings.distanceUnit.abbreviated)")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                if badgeNumber != 0 {
                    Spacer(minLength: 0)
                    
                    Image(systemName: "\(badgeNumber).circle.fill")
                        .foregroundStyle(Color.white, Color.red)
                }
            }
            .padding(.horizontal)
        }
        .padding([.horizontal, .top], 5)
        .padding(.bottom, 10)
        .background {
            RoundedRectangle.adaptive
                .fill(Color(.tertiarySystemBackground))
                .strokeBorder(isPad && isSelected ? Color.secondary : Color.secondary.opacity(0.5), lineWidth: isPad && isSelected ? 2 : colorScheme == .dark ? 0 : 0.5)
        }
        .containerShape(RoundedRectangle.adaptive)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    // Compact vehicle card, with small image and horizontal layout
    private var compactListItem: some View {
        HStack {
            vehicleImage
                .imageScale(.small)
                .frame(width: 100, height: 75)
                .aspectRatio(1.5, contentMode: .fit)
                .fixedSize(horizontal: true, vertical: false)
                .clipShape(ContainerRelativeShape())
                .overlay(
                    ContainerRelativeShape()
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 0.25)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(vehicle.name)
                        .font(.subheadline.bold())
                        .multilineTextAlignment(.leading)
                    
                    if badgeNumber != 0 {
                        Image(systemName: "\(badgeNumber).circle.fill")
                            .foregroundStyle(Color.white, Color.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(vehicle.odometer) \(settings.distanceUnit.abbreviated)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(5)
        .background {
            RoundedRectangle.adaptive
                .fill(Color(.tertiarySystemBackground))
                .strokeBorder(isPad && isSelected ? Color.secondary : Color.secondary.opacity(0.5), lineWidth: isPad && isSelected ? 2 : colorScheme == .dark ? 0 : 0.5)
        }
        .containerShape(RoundedRectangle.adaptive)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    private var vehicleImage: some View {
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
    private var badgeNumber: Int {
        return services.filter({ $0.serviceStatus == .due || $0.serviceStatus == .overDue }).count
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleListRowView(vehicle: vehicle, isSelected: true)
}
