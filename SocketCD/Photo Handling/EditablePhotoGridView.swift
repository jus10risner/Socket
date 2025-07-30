//
//  EditablePhotoGridView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct EditablePhotoGridView: View {
    @Binding var photos: [Photo]
    
    let columnCount = 4
    let gridSpacing = 10.0
    
    var body: some View {
        if !photos.isEmpty {
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: gridSpacing), count: columnCount), spacing: gridSpacing) {
                ForEach(photos.sorted { $0.timeStamp < $1.timeStamp }, id: \.id) { photo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(Color.clear)
                            .aspectRatio(1.0, contentMode: .fill)
                            .overlay(
                                Image(uiImage: photo.converted)
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        
                        Button {
                            delete(photo: photo)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .gray)
                                .opacity(0.7)
                                .accessibilityLabel("Delete Image")
                        }
                        .buttonStyle(.plain)
                    }
                }
                // prevents images from flickering when animating, after an item is deleted
                .id(UUID())
            }
            .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .animation(.easeInOut, value: photos)
        }
    }
    
    // MARK: - Methods
    
    // Deletes a given photo from the photos array
    func delete(photo: Photo) {
        if let index = photos.firstIndex(of: photo) {
            photos.remove(at: index)
        }
    }
}
