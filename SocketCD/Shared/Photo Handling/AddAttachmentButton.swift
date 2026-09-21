//
//  AddAttachmentButton.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import AVFoundation
import CoreData
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct AddAttachmentButton: View {
    @Environment(\.managedObjectContext) var context
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @Binding var photos: [Photo]
    @Binding var documents: [AttachedDocument]
    
    @State private var showingPhotosPicker = false
    @State private var showingDocumentPicker = false
    @State private var showingPhotoError = false
    @State private var showingDocumentError = false
    @State private var isLoadingPhotos = false
    
    @State private var capturedImage: UIImage?
    @State private var selectedImages: [PhotosPickerItem] = []
    
    var body: some View {
        HStack {
            if isLoadingPhotos {
                ProgressView()
                Text("Adding Photos…")
            } else {
                Image(systemName: "paperclip")
                Text("Add Attachment...")
            }
        }
        .foregroundStyle(.tint)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
        
//        Label("Add Attachment...", systemImage: "paperclip")
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .accessibilityHidden(true)
            .overlay {
                Menu {
                    Button("Choose Photo", systemImage: "photo.on.rectangle") {
                        UIApplication.shared
                            .sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        
                        // Dismisses keyboard, if visible
                        showingPhotosPicker = true
                    }
                
                    Button("Take Photo", systemImage: "camera") {
                        Task {
                            await cameraViewModel
                                .requestCameraAccessAndAvailability()
                        }
                    }

                    Button("Choose PDF", systemImage: "document") {
                        UIApplication.shared
                            .sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        
                        showingDocumentPicker = true
                    }
                } label: {
                    Color.clear
                        .accessibilityLabel("Add Attachment")
                        .accessibilityHint("Double-tap to open attachments menu")
                }
            }
            .onChange(of: selectedImages) {
                Task {
                    await loadSelectedImages()
                }
            }
            .photosPicker(
                isPresented: $showingPhotosPicker,
                selection: $selectedImages,
                matching: .images
            )
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true,
                onCompletion: importDocuments
            )
            .fullScreenCover(isPresented: $cameraViewModel.showingCamera, onDismiss: {
                Task {
                    await verifyAndAppend()
                }
            }) {
                CameraCapture(
                    image: $capturedImage,
                    isPresented: $cameraViewModel.showingCamera
                )
                .ignoresSafeArea()
            }
            .alert(
                "No Camera Found",
                isPresented: $cameraViewModel.showingCameraUnavailableAlert
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(
                    "This device does not appear to have a functioning camera."
                )
            }
            .alert(
                "No Camera Access",
                isPresented: $cameraViewModel.showingCameraAccessAlert
            ) {
                Button("Go to Settings") {
                    Task {
                        await AppSettingsStore.openSocketSettings()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(
                    "To use the camera, you will need to turn on camera access for Socket, in the Settings app."
                )
            }
            .alert("Image Error", isPresented: $showingPhotoError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "There was a problem saving that image. Please try another image."
                )
            }
            .alert("Document Error", isPresented: $showingDocumentError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "There was a problem saving that PDF. Please try another document."
                )
            }
    }
    
    // MARK: - Methods
    
    // Verifies an image captured via the camera, then appends it to the photos array
    private func verifyAndAppend() async {
        if let selectedImage = capturedImage, let newPhoto = Photo.create(from: selectedImage, in: context) {
            photos.append(newPhoto)
        }
    }
    
    // Verifies images captured via the PhotosPicker, then appends them to the photos array
    private func loadSelectedImages() async {
        let items = selectedImages
        guard !items.isEmpty else { return }

        isLoadingPhotos = true
        defer {
            selectedImages.removeAll()
            isLoadingPhotos = false
        }

        let loadedImages = await withTaskGroup(
            of: (Int, Data?).self,
            returning: [(Int, Data?)].self
        ) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self) else {
                            return (index, nil)
                        }

                        return (index, PhotoDataProcessor.jpegData(from: data))
                    } catch {
                        return (index, nil)
                    }
                }
            }

            var results: [(Int, Data?)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }
        }

        let imageData = loadedImages.compactMap(\.1)
        let newPhotos = imageData.map { Photo.create(from: $0, in: context) }

        withAnimation {
            photos.append(contentsOf: newPhotos)
        }

        if newPhotos.count != items.count {
            showingPhotoError = true
        }
    }

    private func importDocuments(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            var newDocuments: [AttachedDocument] = []

            for url in urls {
                newDocuments.append(
                    try AttachedDocument.create(from: url, in: context)
                )
            }

            withAnimation(.smooth) {
                documents.append(contentsOf: newDocuments)
            }
        } catch {
            showingDocumentError = true
        }
    }
}
