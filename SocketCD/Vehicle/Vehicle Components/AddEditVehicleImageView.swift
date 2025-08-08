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
    @EnvironmentObject var settings: AppSettings
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
        .animation(.default, value: draftVehicle.photo)
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedImage, matching: .images)
        .fullScreenCover(isPresented: $cameraViewModel.showingCamera, onDismiss: verifyAndAdd) {
            CameraCapture(image: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImage) { loadSelectedImage() }
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
                        .padding(10)
                }
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                
                if draftVehicle.photo != nil {
                    Button {
                        withAnimation {
                            draftVehicle.photo = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .gray)
                            .accessibilityLabel("Delete Photo")
                    }
                    .padding(10)
                    .buttonStyle(.plain)
                }
            }
        }
        .aspectRatio(2, contentMode: .fit)
        .frame(maxWidth: 300)
        .animation(nil, value: draftVehicle.photo)
    }
    
    private var photoMenu: some View {
        Menu {
            Button {
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
            Label("Vehicle Photo", systemImage: "camera.fill")
                .foregroundStyle(Color.white)
        }
        .buttonStyle(.borderedProminent)
        .padding(.top, 5)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Methods
    
    // Verifies that a valid image has been captured via the camera, then converts it to binary data
    private func verifyAndAdd() {
        Task {
            if let capturedImage {
                let newPhoto = Photo.create(from: capturedImage, in: context)
                
                withAnimation {
                    draftVehicle.photo = newPhoto
                }
            }
        }
    }
    
    // Verifies that a valid image has been selected via the PhotosPicker, then converts it to binary data
    private func loadSelectedImage() {
        Task {
            guard let selectedImage else { return }
            
            if let data = try await selectedImage.loadTransferable(type: Data.self),
                let uiImage = UIImage(data: data) {
                let newPhoto = Photo.create(from: uiImage, in: context)
                
                withAnimation {
                    draftVehicle.photo = newPhoto
                }
                
                self.selectedImage = nil
            }
        }
    }
}

#Preview {
    AddEditVehicleImageView(draftVehicle: DraftVehicle())
}
