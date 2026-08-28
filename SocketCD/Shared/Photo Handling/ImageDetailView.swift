//
//  ImageDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import CoreData
import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

struct ImageDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let pages: [PhotoPage]
    private let transitionNamespace: Namespace.ID

    @State private var selectedPhotoID: NSManagedObjectID
    @State private var isZoomed = false

    init(
        photos: [Photo],
        selectedPhotoID: NSManagedObjectID,
        transitionNamespace: Namespace.ID
    ) {
        self.pages = photos.map { PhotoPage(id: $0.objectID, image: $0.converted) }
        self.transitionNamespace = transitionNamespace
        self._selectedPhotoID = State(initialValue: selectedPhotoID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                
                PhotoPager(
                    pages: pages,
                    selectedPhotoID: $selectedPhotoID,
                    isZoomed: $isZoomed
                )
            }
            .ignoresSafeArea()
            .toolbar {
                if pages.count > 1 {
                    ToolbarItem(placement: .principal) {
                        Text("\(selectedIndex + 1) of \(pages.count)")
                            .foregroundStyle(.white)
                            .accessibilityLabel("Photo \(selectedIndex + 1) of \(pages.count)")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if let shareablePhoto, let image = selectedPage?.image {
                        ShareLink(
                            item: shareablePhoto,
                            preview: SharePreview("Photo", image: Image(uiImage: image))
                        ) {
                            Label("Share Image", systemImage: "square.and.arrow.up")
                        }
                        .labelStyle(.iconOnly)
                        .tint(.white)
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss", systemImage: "xmark", action: dismiss.callAsFunction)
                        .tint(.white)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .statusBarHidden()
            .onChange(of: currentPhotoID) {
                isZoomed = false
            }
        }
        .navigationTransition(.zoom(sourceID: currentPhotoID, in: transitionNamespace))
    }

    private var currentPhotoID: NSManagedObjectID {
        selectedPhotoID
    }

    private var selectedIndex: Int {
        pages.firstIndex { $0.id == currentPhotoID } ?? 0
    }

    private var selectedPage: PhotoPage? {
        pages.first { $0.id == currentPhotoID }
    }

    private var shareablePhoto: ShareablePhoto? {
        guard let data = selectedPage?.image?.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        return ShareablePhoto(data: data)
    }
}

private struct PhotoPager: View {
    let pages: [PhotoPage]

    @Binding var selectedPhotoID: NSManagedObjectID
    @Binding var isZoomed: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(pages) { page in
                        PhotoPageView(page: page, isZoomed: $isZoomed)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .id(page.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: selectedPhotoIDBinding)
            .onScrollTargetVisibilityChange(idType: NSManagedObjectID.self) { visiblePhotoIDs in
                if let visiblePhotoID = visiblePhotoIDs.first {
                    selectedPhotoID = visiblePhotoID
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollDisabled(isZoomed)
        }
    }

    private var selectedPhotoIDBinding: Binding<NSManagedObjectID?> {
        Binding(
            get: { selectedPhotoID },
            set: { newValue in
                if let newValue {
                    selectedPhotoID = newValue
                }
            }
        )
    }
}

private struct PhotoPageView: View {
    let page: PhotoPage
    @Binding var isZoomed: Bool

    var body: some View {
        if let image = page.image {
            ImageViewer(image: image, isZoomed: $isZoomed)
        } else {
            ContentUnavailableView("Image unavailable", systemImage: "photo")
                .foregroundStyle(.white)
        }
    }
}

private struct PhotoPage: Identifiable {
    let id: NSManagedObjectID
    let image: UIImage?
}

private struct ShareablePhoto: Transferable, Sendable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { photo in
            photo.data
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    let context = DataController.preview.container.viewContext
    let photo = Photo.create(from: UIImage(imageLiteralResourceName: "example"), in: context)

    if let photo {
        ImageDetailView(
            photos: [photo],
            selectedPhotoID: photo.objectID,
            transitionNamespace: namespace
        )
    }
}
