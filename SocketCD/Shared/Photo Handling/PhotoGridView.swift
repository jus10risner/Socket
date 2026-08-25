//
//  PhotoGridView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData
import SwiftUI

struct PhotoGridView: View {
    @Binding var photos: [Photo]
    let isEditable: Bool

    @Namespace private var photoTransition
    @State private var selectedPhoto: SelectedPhoto?
    
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 5)]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(photos, id: \.objectID) { photo in
                if isEditable {
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
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .fullScreenCover(item: $selectedPhoto) { selection in
            ImageDetailView(
                photos: photos,
                selectedPhotoID: selection.id,
                transitionNamespace: photoTransition
            )
        }
    }
    
    private func delete(_ photo: Photo) {
        photos.removeAll { $0.objectID == photo.objectID }
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
    
    PhotoGridView(photos: .constant(photo.map { [$0] } ?? []), isEditable: false)
}
