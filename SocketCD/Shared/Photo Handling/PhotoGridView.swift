//
//  PhotoGridView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData
import SwiftUI

struct PhotoGridView: View {
    private let editablePhotos: Binding<[Photo]>?
    private let readOnlyPhotos: [Photo]

    @Namespace private var photoTransition
    @State private var selectedPhoto: SelectedPhoto?
    
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 5)]
    
    private var photos: [Photo] {
        editablePhotos?.wrappedValue ?? readOnlyPhotos
    }
    
    init(photos: Binding<[Photo]>) {
        self.editablePhotos = photos
        self.readOnlyPhotos = []
    }

    init(photos: [Photo]) {
        self.editablePhotos = nil
        self.readOnlyPhotos = photos
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(photos, id: \.objectID) { photo in
                if editablePhotos != nil {
                    ZStack(alignment: .topTrailing) {
                        PhotoThumbnail(photo: photo)

                        Button("Delete Image", systemImage: "xmark.circle.fill") {
                            withAnimation {
                                delete(photo)
                            }
                        }
                        .buttonStyle(.plain)
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .gray)
                        .padding(5)
                    }
                } else {
                    Button {
                        selectedPhoto = SelectedPhoto(id: photo.objectID)
                    } label: {
                        PhotoThumbnail(photo: photo)
                            .matchedTransitionSource(id: photo.objectID, in: photoTransition)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .fullScreenCover(item: $selectedPhoto) { selection in
            ImageDetailView(
                photos: photos,
                selectedPhotoID: selection.id,
                transitionNamespace: photoTransition
            )
        }
    }
    
    private func delete(_ photo: Photo) {
        guard let binding = editablePhotos else { return }
        binding.wrappedValue.removeAll { $0.objectID == photo.objectID }
    }
}

private struct SelectedPhoto: Identifiable {
    let id: NSManagedObjectID
}

private struct PhotoThumbnail: View {
    let photo: Photo

    var body: some View {
        RoundedRectangle.adaptive
            .fill(Color.clear)
            .aspectRatio(1.5, contentMode: .fit)
            .overlay {
                if let uiImage = photo.converted {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .contentShape(Rectangle())
                } else {
                    Color.clear
                }
            }
            .clipShape(RoundedRectangle.adaptive)
            .overlay {
                RoundedRectangle.adaptive
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
            }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let photo = Photo.create(from: UIImage(imageLiteralResourceName: "example"), in: context)
    
    PhotoGridView(photos: photo.map { [$0] } ?? [])
}
