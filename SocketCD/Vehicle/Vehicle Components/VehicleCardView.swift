//
//  VehicleCardView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/24/24.
//

import SwiftUI

struct VehicleCardView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var vehicle: Vehicle
    @Binding var quickFillupVehicle: Vehicle?
    @Binding var quickEditVehicle: Vehicle?
    @Binding var vehicleToDelete: Vehicle?
    @Binding var showingDeleteAlert: Bool
    
    @FetchRequest var services: FetchedResults<Service>
    
    init(vehicle: Vehicle, quickFillupVehicle: Binding<Vehicle?>?, quickEditVehicle: Binding<Vehicle?>?, vehicleToDelete: Binding<Vehicle?>?, showingDeleteAlert: Binding<Bool>) {
        self.vehicle = vehicle
        self._quickFillupVehicle = quickFillupVehicle ?? Binding.constant(nil)
        self._quickEditVehicle = quickEditVehicle ?? Binding.constant(nil)
        self._vehicleToDelete = vehicleToDelete ?? Binding.constant(nil)
        self._showingDeleteAlert = showingDeleteAlert
        self._services = FetchRequest(
            entity: Service.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .colorSchemeBackground(colorScheme: colorScheme)
                .shadow(color: .secondary.opacity(0.4), radius: colorScheme == .dark ? 0 : 2)
            
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.clear)
                    .aspectRatio(2, contentMode: .fit)
                    .overlay(
                        ZStack {
                            if let carPhoto = vehicle.photo {
                                VehiclePhotoView(carPhoto: carPhoto)
                            } else {
                                PlaceholderPhotoView(backgroundColor: vehicle.backgroundColor)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.black.opacity(0.3), lineWidth: 0.25)
                            .foregroundStyle(Color.clear)
                    }
                    .padding([.horizontal, .top], 5)
                    .accessibilityHidden(true)
                
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(vehicle.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        
                        Text("\(vehicle.odometer) \(settings.shortenedDistanceUnit)")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Spacer()
                    
                    if serviceDue == true {
                        maintenanceAlert
                            .onChange(of: serviceDue) { _ in
                                animateMaintenanceAlert()
                            }
                    }
                    
                    vehicleMenu
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 15)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    
    // MARK: - Views
    
    // Animated symbol, to draw user attention to a vehicle that is due for service
    var maintenanceAlert: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .symbolRenderingMode(.multicolor)
            .font(.title3)
            .foregroundStyle(.red)
            .overlay(
                Circle()
                    .stroke(.red)
                    .scaleEffect(isAnimating ? 2 : 0.8)
                    .opacity(2 - (isAnimating ? 2 : 0))
                    .animation(isAnimating ? .easeInOut(duration: 1.5)
                        .delay(2)
                        .repeatForever(autoreverses: false) : .easeOut(duration: 0), value: isAnimating)
            )
            .onAppear { animateMaintenanceAlert() }
            .accessibilityLabel("Maintenance Due")
    }
    
    var vehicleMenu: some View {
        Menu {
            Button {
                quickFillupVehicle = vehicle
            } label: {
                Label("Add Fill-up", systemImage: "fuelpump")
            }
                
            Section {
                Button {
                    quickEditVehicle = vehicle
                } label: {
                    Label("Edit Vehicle", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    vehicleToDelete = vehicle
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Vehicle", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Color.secondary)
                .frame(width: 20, height: 20)
        }
        .highPriorityGesture(TapGesture())
        .buttonStyle(.plain)
        .padding(.leading, 5)
    }
    
    
    // MARK: - Methods
    
    // Starts or restarts animation of the maintenanceAlert component
    func animateMaintenanceAlert() {
        if isAnimating {
            isAnimating = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isAnimating = true
        }
    }
    
    
    // MARK: - Computed Properties
    
    // Determines whether to show maintenanceAlert for the given vehicle
    var serviceDue: Bool {
        var numberDue = 0

        if services.contains(where: { $0.serviceStatus == .due || $0.serviceStatus == .overDue }) {
            numberDue += 1
        }
//        for service in services {
//            if service.serviceStatus == .due || service.serviceStatus == .overDue {
//                numberDue += 1
//            }
//        }

        if numberDue > 0 {
            return true
        } else {
            return false
        }
    }
}

#Preview {
    VehicleCardView(vehicle: Vehicle(context: DataController.preview.container.viewContext), quickFillupVehicle: nil, quickEditVehicle: nil, vehicleToDelete: nil, showingDeleteAlert: .constant(false))
        .environmentObject(AppSettings())
}
