//
//  VehicleCardView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/24/24.
//

import SwiftUI

struct VehicleCardView: View {
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
    @State private var cornerRadius: CGFloat = 20
    
    @State private var quickFillupVehicle: Vehicle?
//    @State private var quickEditVehicle: Vehicle?
//    @State private var vehicleToDelete: Vehicle?
//    @State private var showingDeleteAlert = false
    
    var body: some View {
//        cardView
        alternateCardView
    }
    
    private var alternateCardView: some View {
        VStack(spacing: 10) {
            vehicleImageCard
            
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
                        .onChange(of: serviceDue) {
                            animateMaintenanceAlert()
                        }
                }
                
//                vehicleMenu
            }
            .padding(.horizontal)
        }
        .padding([.horizontal, .top], 5)
        .padding(.bottom, 10)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .colorSchemeBackground(colorScheme: colorScheme)
                .shadow(color: .secondary.opacity(0.4), radius: colorScheme == .dark ? 0 : 2)
        }
        .swipeActions(edge: .leading) {
            Button {
                quickFillupVehicle = vehicle
            } label: {
                Label("Add Fill-up", systemImage: "fuelpump")
                    .labelStyle(.iconOnly)
            }
            .tint(Color.defaultFillupsAccent)
        }
//        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
//            Button {
//                vehicleToDelete = vehicle
//                showingDeleteAlert = true
//            } label: {
//                Label("Delete Vehicle", systemImage: "trash")
//                    .labelStyle(.iconOnly)
//            }
//            .tint(Color.red)
//            
//            Button {
//                quickEditVehicle = vehicle
//            } label: {
//                Label("Edit Vehicle", systemImage: "pencil")
//                    .labelStyle(.iconOnly)
//            }
//            .tint(Color.defaultAppAccent)
//        }
        .sheet(item: $quickFillupVehicle) { vehicle in
//            AddFillupView(vehicle: vehicle, quickFill: true)
            AddEditFillupView(vehicle: vehicle)
                .tint(settings.accentColor(for: .fillupsTheme))
        }
//        .sheet(item: $quickEditVehicle) { vehicle in
//            EditVehicleView(vehicle: vehicle)
//                .tint(settings.accentColor(for: .appTheme))
//        }
//        .confirmationDialog("Permanently delete \(vehicleToDelete?.name ?? "this vehicle") and all of its records? \nThis cannot be undone.", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
//            Button("Delete", role: .destructive) {
//                withAnimation {
//                    if let vehicleToDelete {
//                        DataController.shared.delete(vehicleToDelete)
//                    }
//                    
//                    vehicleToDelete = nil
//                }
//            }
//            
//            Button("Cancel", role: .cancel) { vehicleToDelete = nil }
//        }
    }
    
//    private var cardView: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 15)
//                .colorSchemeBackground(colorScheme: colorScheme)
//                .shadow(color: .secondary.opacity(0.4), radius: colorScheme == .dark ? 0 : 2)
//            
//            VStack(spacing: 0) {
//                RoundedRectangle(cornerRadius: 10)
//                    .foregroundStyle(Color.clear)
//                    .aspectRatio(2, contentMode: .fit)
//                    .overlay(
//                        ZStack {
//                            if let carPhoto = vehicle.photo {
//                                VehiclePhotoView(carPhoto: carPhoto)
//                            } else {
//                                PlaceholderPhotoView(backgroundColor: vehicle.backgroundColor)
//                            }
//                        }
//                    )
//                    .clipShape(RoundedRectangle(cornerRadius: 10))
//                    .overlay {
//                        RoundedRectangle(cornerRadius: 10)
//                            .stroke(.black.opacity(0.3), lineWidth: 0.25)
//                            .foregroundStyle(Color.clear)
//                    }
//                    .padding([.horizontal, .top], 5)
//                    .accessibilityHidden(true)
//                
//                HStack {
//                    VStack(alignment: .leading, spacing: 0) {
//                        Text(vehicle.name)
//                            .font(.headline)
//                            .lineLimit(1)
//                        
//                        
//                        Text("\(vehicle.odometer) \(settings.distanceUnit.abbreviated)")
//                            .font(.caption)
//                            .foregroundStyle(Color.secondary)
//                    }
//                    
//                    Spacer()
//                    
//                    if serviceDue == true {
//                        maintenanceAlert
//                            .onChange(of: serviceDue) {
//                                animateMaintenanceAlert()
//                            }
//                    }
//                    
////                    vehicleMenu
//                }
//                .padding(.vertical, 7)
//                .padding(.horizontal, 15)
//            }
//        }
//        .fixedSize(horizontal: false, vertical: true)
//    }
    // MARK: - Views
    
    var vehicleImageCard: some View {
        ZStack {
            Group {
                if let carPhoto = vehicle.photo {
                    VehiclePhotoView(carPhoto: carPhoto)
                } else {
                    PlaceholderPhotoView(backgroundColor: vehicle.backgroundColor)
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 5))
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius - 5)
                .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
        )
        .aspectRatio(2, contentMode: .fit)
    }
    
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
    
//    var vehicleMenu: some View {
//        Menu {
//            Button {
//                quickFillupVehicle = vehicle
//            } label: {
//                Label("Add Fill-up", systemImage: "fuelpump")
//            }
//                
//            Section {
//                Button {
//                    quickEditVehicle = vehicle
//                } label: {
//                    Label("Edit Vehicle", systemImage: "pencil")
//                }
//                
//                Button(role: .destructive) {
//                    vehicleToDelete = vehicle
//                    showingDeleteAlert = true
//                } label: {
//                    Label("Delete Vehicle", systemImage: "trash")
//                }
//            }
//        } label: {
//            Image(systemName: "ellipsis")
//                .foregroundStyle(Color.secondary)
//                .frame(width: 20, height: 20)
//        }
//        .highPriorityGesture(TapGesture())
//        .buttonStyle(.plain)
//        .padding(.leading, 5)
//    }
    
    
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
        return services.contains(where: { $0.serviceStatus == .due || $0.serviceStatus == .overDue })
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleCardView(vehicle: vehicle)
        .environmentObject(AppSettings())
}
