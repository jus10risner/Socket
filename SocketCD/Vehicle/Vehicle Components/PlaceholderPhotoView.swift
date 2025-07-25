//
//  PlaceholderPhotoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct PlaceholderPhotoView: View {
    let backgroundColor: Color
    
    var body: some View {
        ZStack {
            backgroundColor
            
            Image(systemName: "car.fill")
                .font(.system(size: 50))
                .foregroundStyle(.ultraThickMaterial)
        }
        .environment(\.colorScheme, .light)
        .accessibilityLabel("Car symbol on a solid-color background")
    }
}

#Preview {
    PlaceholderPhotoView(backgroundColor: .indigo)
}
