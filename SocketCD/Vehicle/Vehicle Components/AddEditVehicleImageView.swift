//
//  AddEditVehicleImageView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import SwiftUI

struct AddEditVehicleImageView: View {
    @ObservedObject var draftVehicle: DraftVehicle
    
    var body: some View {
        vehicleRepresentation
    }
    
    
    // MARK: - Views
    
    // Either the selected photo for this vehicle, or a vehicle graphic, with the selected background color
    private var vehicleRepresentation: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(Color.clear)
            .aspectRatio(2, contentMode: .fit)
            .overlay(
                ZStack {
                    if let photo = draftVehicle.photo {
                        VehiclePhotoView(carPhoto: photo)
                    } else {
                        PlaceholderPhotoView(backgroundColor: draftVehicle.selectedColor)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.black.opacity(0.3), lineWidth: 0.25)
                    .foregroundStyle(Color.clear)
                
                draftVehicle.photo == nil ? nil : deletePhotoButton
            }
            .transaction { transaction in
                transaction.animation = nil
            }
    }
    
    // Button component that sets the selected vehicle photo to nil
    private var deletePhotoButton: some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    withAnimation {
                        draftVehicle.photo = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .gray)
                        .accessibilityLabel("Delete Photo")
                }
                .padding(10)
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AddEditVehicleImageView(draftVehicle: DraftVehicle())
}
