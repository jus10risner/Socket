//
//  PhotoGridView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct PhotoGridView: View {
    private let editablePhotos: Binding<[Photo]>?
    private let readOnlyPhotos: [Photo]
    
    private let isEditable: Bool
    @State private var selectedPhoto: Photo?
    
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 5)]
    
    private var photos: [Photo] {
        editablePhotos?.wrappedValue ?? readOnlyPhotos
    }
    
    // MARK: - Initializers
        
    // Editable: pass a Binding<[Photo]>
    init(photos: Binding<[Photo]>) {
        self.editablePhotos = photos
        self.readOnlyPhotos = []
        self.isEditable = true
    }
    
    // Read-only: pass an array directly
    init(photos: [Photo]) {
        self.editablePhotos = nil
        self.readOnlyPhotos = photos
        self.isEditable = false
    }
    
    // MARK: - Body
    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(photos, id: \.id) { photo in
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle.adaptive
                        .fill(Color.clear)
                        .aspectRatio(1.5, contentMode: .fit)
                        .overlay {
                            if let uiImage = photo.converted {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.clear
                            }
                        }
                        .clipShape(RoundedRectangle.adaptive)
                        .overlay {
                            RoundedRectangle.adaptive
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                        }
                        .onTapGesture {
                            if !isEditable {
                                selectedPhoto = photo
                            }
                        }
                    
                    if isEditable {
                        Button("Delete Image", systemImage: "xmark.circle.fill") {
                            withAnimation {
                                delete(photo: photo)
                            }
                        }
                        .buttonStyle(.plain)
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .gray)
                        .padding(5)
                    }
                }
            }
            .id(UUID()) // prevents flicker when deleting
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            if let uiImage = photo.converted {
                ImageDetailView(image: uiImage)
            } else {
                Text("Image unavailable")
                    .font(.headline)
                    .padding()
            }
        }
    }
    
    // Deletes a given photo from the photos array
    private func delete(photo: Photo) {
        guard let binding = editablePhotos else { return }
        binding.wrappedValue.removeAll { $0.id == photo.id }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let photo = Photo.create(from: UIImage(imageLiteralResourceName: "example"), in: context)
    
    PhotoGridView(photos: photo.map { [$0] } ?? [])
}
