//
//  AddPhotoButton.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import AVFoundation
import SwiftUI

struct AddPhotoButton: View {
    @Environment(\.managedObjectContext) var context
    @StateObject private var cameraViewModel = CameraViewModel()
    let cameraManager = CameraManager()
    
    @State private var showingImagePicker = false
    @State private var showingPhotoError = false
    
    @State private var uiImage: UIImage?
    @Binding var photos: [Photo]
    
    var body: some View {
        HStack {
            Spacer()
            
            Menu {
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showingImagePicker = true
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
                Label("Add Photo", systemImage: "camera")
            }
            .font(.body)
            
            Spacer()
        }
        .onChange(of: uiImage) { verifyAndAppend() }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $uiImage)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $cameraViewModel.showingCamera) {
            CameraCapture(image: $uiImage)
                .ignoresSafeArea()
        }
        .alert("No Camera Found", isPresented: $cameraViewModel.showingCameraUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\nThis device does not appear to have a functioning camera.")
        }
        .alert("No Camera Access", isPresented: $cameraViewModel.showingCameraAccessAlert) {
            Button("Go to Settings") {
                Task {
                    await cameraManager.openSocketSettings()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\nTo use the camera, you will need to turn on camera access for Socket, in the Settings app.")
        }
        .alert("Image Error", isPresented: $showingPhotoError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\nThere was a problem saving that image. Please try another image.")
        }
        .textCase(nil)
    }
    
    // MARK: - Methods
    
    // Verifies that an image exists, then creates a new photo object and appends it to the photos array, to be passed to EditablePhotoGridView
    func verifyAndAppend() {
        if let selectedImage = uiImage {
            if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                let newPhoto = Photo(context: context)
                newPhoto.id = UUID()
                newPhoto.timeStamp = Date.now
                newPhoto.imageData = imageData
                photos.append(newPhoto)
            }
        }
    }
}
