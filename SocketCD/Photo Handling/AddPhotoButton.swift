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
            Button("Photo Library", systemImage: "photo.on.rectangle") {
                showingPhotosPicker = true
            }
            
            Button("Take Photo", systemImage: "camera") {
                Task {
                    await cameraViewModel.requestCameraAccessAndAvailability()
                }
            }
        } label: {
            Label {
                Text("Add Photo...")
            } icon: {
                Image(systemName: "photo")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .tint(Color.primary)
        .onChange(of: selectedImages) {
            Task {
                await loadSelectedImages()
            }
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedImages, matching: .images)
        .fullScreenCover(isPresented: $cameraViewModel.showingCamera, onDismiss: {
            Task {
                await verifyAndAppend()
            }
        }) {
            CameraCapture(image: $capturedImage, isPresented: $cameraViewModel.showingCamera)
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
        defer { selectedImages.removeAll() }
        
        for item in selectedImages {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                    let uiImage = UIImage(data: data),
                    let newPhoto = Photo.create(from: uiImage, in: context) {
                    photos.append(newPhoto)
                } else {
                    showingPhotoError = true
                }
            } catch {
                showingPhotoError = true
            }
        }
    }
}
