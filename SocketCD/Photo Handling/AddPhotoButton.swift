//
//  AddPhotoButton.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import AVFoundation
import PhotosUI
import SwiftUI

struct AddPhotoButton: View {
    @Environment(\.managedObjectContext) var context
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @Binding var photos: [Photo]
    
    @State private var showingPhotosPicker = false
    @State private var showingPhotoError = false
    
    @State private var capturedImage: UIImage?
    @State private var selectedImages: [PhotosPickerItem] = []
    
    var body: some View {
        Menu {
            Button {
//                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showingPhotosPicker = true
            } label: {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
            }
            
            Button {
                Task {
                    await cameraViewModel.requestCameraAccessAndAvailability()
                }
            } label: {
                Label("Take Photo", systemImage: "camera")
            }
        } label: {
            Label {
                Text("Add Photo")
            } icon: {
                ZStack {
                    RoundedRectangle.adaptive
                        .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 0.5, dash: [5, 3]))
                        .background(Color.clear)
                    
                    Image(systemName: "camera")
                }
                .aspectRatio(1.5, contentMode: .fit)
                .frame(maxWidth: .infinity)
            }
            .labelStyle(.iconOnly)
        }
        .onChange(of: selectedImages) { loadSelectedImages() }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedImages, matching: .images)
        .fullScreenCover(isPresented: $cameraViewModel.showingCamera, onDismiss: verifyAndAppend) {
            CameraCapture(image: $capturedImage)
                .ignoresSafeArea()
        }
        .alert("No Camera Found", isPresented: $cameraViewModel.showingCameraUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This device does not appear to have a functioning camera.")
        }
        .alert("No Camera Access", isPresented: $cameraViewModel.showingCameraAccessAlert) {
            Button("Go to Settings") {
                Task {
                    await AppSettings.openSocketSettings()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To use the camera, you will need to turn on camera access for Socket, in the Settings app.")
        }
        .alert("Image Error", isPresented: $showingPhotoError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("There was a problem saving that image. Please try another image.")
        }
        .textCase(nil)
    }
    
    // MARK: - Methods
    
    // Verifies an image captured via the camera, then appends it to the photos array
    private func verifyAndAppend() {
        Task {
            if let selectedImage = capturedImage, let newPhoto = Photo.create(from: selectedImage, in: context) {
                photos.append(newPhoto)
            }
        }
    }
    
    // Verifies images captured via the PhotosPicker, then appends them to the photos array
    private func loadSelectedImages() {
        for item in selectedImages {
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data),
                      let newPhoto = Photo.create(from: uiImage, in: context) else {
                    return
                }

                photos.append(newPhoto)
            }
        }

        // Clear selection after loading
        selectedImages.removeAll()
    }
}
