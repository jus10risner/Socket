//
//  AddEditVehicleImageView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import PhotosUI
import SwiftUI

struct AddEditVehicleImageView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) var context
    
    // MARK: - Observed Objects
    @ObservedObject var draftVehicle: DraftVehicle
    
    // MARK: - State
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var showingPhotosPicker = false
    @State private var showingPhotoError = false
    @State private var capturedImage: UIImage?
    @State private var selectedImage: PhotosPickerItem?
    
    // MARK: - Body
    var body: some View {
        VStack {
            vehicleImage
            
            photoMenu
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedImage, matching: .images)
        .fullScreenCover(isPresented: $cameraViewModel.showingCamera, onDismiss: {
            Task { await verifyAndAdd() }
        }) {
            CameraCapture(image: $capturedImage, isPresented: $cameraViewModel.showingCamera)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImage) {
            Task {
                await loadSelectedImage()
            }
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
            Text("To use the camera, go to Settings and turn on Camera access for Socket")
        }
        .alert("Image Error", isPresented: $showingPhotoError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("There was a problem saving that image. Please try another image.")
        }
    }
    
    
    // MARK: - Views
    
    private var vehicleImage: some View {
        Group {
            if let carPhoto = draftVehicle.photo {
                VehicleImageView(carPhoto: carPhoto)
            } else {
                ZStack(alignment: .bottomTrailing) {
                    VehicleImageView(backgroundColor: draftVehicle.selectedColor)
                    
                    ColorPicker("Select Color", selection: $draftVehicle.selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding()
                }
            }
        }
        .clipped()
        .clipShape(RoundedRectangle.adaptive)
        .overlay {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle.adaptive
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                
                if draftVehicle.photo != nil {
                    Button("Delete Photo", systemImage: "xmark.circle.fill") {
                        draftVehicle.photo = nil
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .gray)
                    .padding(10)
                }
            }
        }
        .aspectRatio(2, contentMode: .fit)
        .frame(maxWidth: 300)
    }
    
    private var photoMenu: some View {
        Menu(draftVehicle.photo != nil ? "Change Photo" : "Add Photo") {
            Button("Choose Photo", systemImage: "photo.on.rectangle") {
                showingPhotosPicker = true
            }
            
            Button("Take Photo", systemImage: "camera") {
                Task {
                    await cameraViewModel.requestCameraAccessAndAvailability()
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Methods
    
    // Verifies that a valid image has been captured via the camera, then converts it to binary data
    private func verifyAndAdd() async {
        if let capturedImage {
            let newPhoto = Photo.create(from: capturedImage, in: context)
            
            draftVehicle.photo = newPhoto
        }
    }
    
    // Verifies that a valid image has been selected via the PhotosPicker, then converts it to binary data
    private func loadSelectedImage() async {
        guard let selectedImage else { return }

        defer { self.selectedImage = nil } // Runs just before exiting the scope of the function

        do {
            if let data = try await selectedImage.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                let newPhoto = Photo.create(from: uiImage, in: context)
                draftVehicle.photo = newPhoto
            } else {
                // Could not decode image data
                showingPhotoError = true
            }
        } catch {
            // Handle errors thrown by loadTransferable
            showingPhotoError = true
        }
    }
}

#Preview {
    AddEditVehicleImageView(draftVehicle: DraftVehicle())
}

