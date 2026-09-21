//
//  FormPhotosView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData
import SwiftUI

struct FormPhotosView: View {
    @Binding var photos: [Photo]
    let isEditable: Bool

    @Namespace private var photoTransition
    @State private var selectedPhoto: SelectedPhoto?
    
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 5)]
    
    var body: some View {
        Group {
            if isEditable {
                EditablePhotoGallery(photos: $photos)
            } else {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(photos, id: \.objectID) { photo in
                        Button {
                            selectedPhoto = SelectedPhoto(id: photo.objectID)
                        } label: {
                            PhotoThumbnail(photo: photo)
                                .matchedTransitionSource(id: photo.objectID, in: photoTransition)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
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
}

private struct EditablePhotoGallery: View {
    @Binding var photos: [Photo]

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 5) {
                ForEach(photos, id: \.objectID) { photo in
                    ZStack(alignment: .topTrailing) {
                        PhotoThumbnail(photo: photo)

                        AttachmentDeleteButton("Delete Image") {
                            withAnimation(.smooth) {
                                photos.removeAll { $0.objectID == photo.objectID }
                            }
                        }
                        .padding(8)
                    }
                    .frame(width: 150)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
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
                CachedPhotoImage(
                    photo: photo,
                    maximumPixelSize: 600,
                    contentMode: .fill
                )
                .contentShape(Rectangle())
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
    
    FormPhotosView(photos: .constant(photo.map { [$0] } ?? []), isEditable: false)
}
