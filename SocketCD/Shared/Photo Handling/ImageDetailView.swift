//
//  ImageDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import CoreData
import SwiftUI

struct ImageDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let pages: [PhotoPage]
    private let transitionNamespace: Namespace.ID

    @State private var selectedPhotoID: NSManagedObjectID
    @State private var scrolledPhotoID: NSManagedObjectID?
    @State private var imageURL: URL?
    @State private var isZoomed = false

    init(
        photos: [Photo],
        selectedPhotoID: NSManagedObjectID,
        transitionNamespace: Namespace.ID
    ) {
        self.pages = photos.map { PhotoPage(id: $0.objectID, image: $0.converted) }
        self.transitionNamespace = transitionNamespace
        self._selectedPhotoID = State(initialValue: selectedPhotoID)
        self._scrolledPhotoID = State(initialValue: selectedPhotoID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                PhotoPager(
                    pages: pages,
                    selectedPhotoID: $selectedPhotoID,
                    scrolledPhotoID: $scrolledPhotoID,
                    isZoomed: $isZoomed
                )
            }
            .toolbar {
                if pages.count > 1 {
                    ToolbarItem(placement: .principal) {
                        Text("\(selectedIndex + 1) of \(pages.count)")
                            .foregroundStyle(.white)
                            .accessibilityLabel("Photo \(selectedIndex + 1) of \(pages.count)")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if let imageURL {
                        ShareLink("Share Image", item: imageURL)
                            .tint(.white)
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss", systemImage: "xmark", action: dismiss.callAsFunction)
                        .tint(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .statusBarHidden()
            .task(id: selectedPhotoID) {
                isZoomed = false
                updateShareURL()
            }
            .onDisappear(perform: removeShareFile)
        }
        .navigationTransition(.zoom(sourceID: selectedPhotoID, in: transitionNamespace))
    }

    private var selectedIndex: Int {
        pages.firstIndex { $0.id == selectedPhotoID } ?? 0
    }

    private var selectedPage: PhotoPage? {
        pages.first { $0.id == selectedPhotoID }
    }

    private func updateShareURL() {
        removeShareFile()
        guard let data = selectedPage?.image?.jpegData(compressionQuality: 0.8) else {
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("image-\(UUID().uuidString).jpg")

        do {
            try data.write(to: url)
            imageURL = url
        } catch {
            imageURL = nil
        }
    }

    private func removeShareFile() {
        guard let imageURL else { return }
        try? FileManager.default.removeItem(at: imageURL)
        self.imageURL = nil
    }
}

private struct PhotoPager: View {
    let pages: [PhotoPage]

    @Binding var selectedPhotoID: NSManagedObjectID
    @Binding var scrolledPhotoID: NSManagedObjectID?
    @Binding var isZoomed: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(pages) { page in
                        PhotoPageView(page: page, isZoomed: $isZoomed)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrolledPhotoID)
            .scrollDisabled(isZoomed)
            .onScrollPhaseChange { _, phase in
                if phase == .idle, let scrolledPhotoID {
                    selectedPhotoID = scrolledPhotoID
                }
            }
        }
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
