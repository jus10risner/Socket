//
//  VehiclePhotoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct VehiclePhotoView: View {
    let carPhoto: Photo
    
    var body: some View {
        GeometryReader { geo in
            Image(uiImage: carPhoto.converted)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height) // Forces the image to obey the parent view's constraints
                .clipped()
                .accessibilityLabel("Vehicle Photo")
        }
    }
}
