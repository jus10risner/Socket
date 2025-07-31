//
//  VehicleImageView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct VehicleImageView: View {
    let carPhoto: Photo?
    let backgroundColor: Color?
    
    init(carPhoto: Photo? = nil, backgroundColor: Color? = nil) {
        self.carPhoto = carPhoto
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        GeometryReader { geo in
            if let backgroundColor {
                ZStack {
                    backgroundColor
                    
                    Image(systemName: "car.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.ultraThickMaterial)
                }
                .environment(\.colorScheme, .light)
            } else if let carPhoto {
                Image(uiImage: carPhoto.converted)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height) // Forces the image to obey the parent view's constraints
                    .clipped()
                    .accessibilityLabel("Vehicle Photo")
            }
        }
    }
}
