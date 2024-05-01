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
        Image(uiImage: carPhoto.converted)
            .resizable()
            .scaledToFill()
            .accessibilityLabel("Vehicle Photo")
    }
}
