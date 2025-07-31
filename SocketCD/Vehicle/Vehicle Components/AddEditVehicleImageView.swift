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
        Group {
            if let carPhoto = draftVehicle.photo {
                VehicleImageView(carPhoto: carPhoto)
            } else {
                VehicleImageView(backgroundColor: draftVehicle.selectedColor)
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                
                if draftVehicle.photo != nil {
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
            }
        }
        .aspectRatio(2, contentMode: .fit)
        .animation(nil, value: draftVehicle.photo)
    }
}

#Preview {
    AddEditVehicleImageView(draftVehicle: DraftVehicle())
}
