//
//  PhotoGridView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct PhotoGridView: View {
    let photos: [Photo]
    
    @State private var selectedPhoto: Photo?
    
    let columnCount = 4
    let gridSpacing = 10.0
    
    var body: some View {
        Section {
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: gridSpacing), count: columnCount), spacing: gridSpacing) {
                ForEach(photos, id: \.id) { photo in
                    Button {
                        selectedPhoto = photo
                    } label: {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(Color.clear)
                            .aspectRatio(1.0, contentMode: .fill)
                            .overlay(
                                Image(uiImage: photo.converted)
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .fullScreenCover(item: $selectedPhoto) { photo in
                ImageDetailView(image: photo.converted)
            }
        }
    }
}
