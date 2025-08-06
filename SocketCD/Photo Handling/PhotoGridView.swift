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
//        if !photos.isEmpty {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(photos, id: \.id) { photo in
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                            .aspectRatio(1.5, contentMode: .fit)
                            .overlay(
                                Image(uiImage: photo.converted)
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onTapGesture {
                                if !isEditable {
                                    selectedPhoto = photo
                                }
                            }
                        
                        if isEditable {
                            Button {
                                delete(photo: photo)
                            } label: {
                                Label("Delete Image", systemImage: "xmark.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .font(.title2)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .gray)
                                    .opacity(0.7)
                            }
                            .buttonStyle(.plain)
                            .padding(5)
                        }
                    }
                }
                .id(UUID()) // prevents flicker when deleting
            }
            .fullScreenCover(item: $selectedPhoto) { photo in
                ImageDetailView(image: photo.converted)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .animation(.easeInOut, value: photos)
//        }
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
