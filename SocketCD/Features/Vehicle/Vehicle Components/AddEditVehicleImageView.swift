//
//  AddEditVehicleImageView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import CoreData
import PhotosUI
import SwiftUI

struct AddEditVehicleImageView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
        VStack(spacing: 15) {
            vehicleImage
            
            customizationButtons
        }
        .frame(maxWidth: .infinity)
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedImage, matching: .images)
        .fullScreenCover(isPresented: $cameraViewModel.showingCamera, onDismiss: saveCapturedPhoto) {
            CameraCapture(image: $capturedImage, isPresented: $cameraViewModel.showingCamera)
                .ignoresSafeArea()
        }
        .task(id: selectedImage) {
            await loadSelectedImage(selectedImage)
        }
        .alert("No Camera Found", isPresented: $cameraViewModel.showingCameraUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This device does not appear to have a functioning camera.")
        }
        .alert("No Camera Access", isPresented: $cameraViewModel.showingCameraAccessAlert) {
            Button("Go to Settings") {
                Task {
                    await AppSettingsStore.openSocketSettings()
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            draftVehicle.photo != nil
            ? Text("Vehicle photo is shown.")
            : Text("No photo selected. Current color is shown.")
        )
        .tint(nil)
    }
    
    
    // MARK: - Views
    
    private var vehicleImage: some View {
        ZStack {
            if let carPhoto = draftVehicle.photo {
                VehicleImageView(carPhoto: carPhoto)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                VehicleImageView(backgroundColor: draftVehicle.selectedColor)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: draftVehicle.photo != nil)
        .clipShape(RoundedRectangle.adaptive)
        .overlay {
            RoundedRectangle.adaptive
                .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
        }
        .aspectRatio(2, contentMode: .fit)
        .frame(maxWidth: 300)
    }
    
    private var customizationButtons: some View {
        HStack(spacing: 20) {
            if draftVehicle.photo == nil {
                VehicleColorPicker(selectedColor: $draftVehicle.selectedColor)
            }
            
            Menu(draftVehicle.photo == nil ? "Add Photo" : "Change Photo", systemImage: "photo") {
                Button("Choose Photo", systemImage: "photo") {
                    showingPhotosPicker = true
                }
                
                Button("Take Photo", systemImage: "camera") {
                    Task {
                        await cameraViewModel.requestCameraAccessAndAvailability()
                    }
                }
            }
            
            if draftVehicle.photo != nil {
                Button("Remove Photo", systemImage: "xmark") {
                    draftVehicle.photo = nil
                }
                .tint(nil)
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .animation(reduceMotion ? nil : .spring, value: draftVehicle.photo != nil)
    }
    
    // MARK: - Methods
    
    private func saveCapturedPhoto() {
        guard let capturedImage else { return }
        defer { self.capturedImage = nil }
        setPhoto(from: capturedImage)
    }

    private func setPhoto(from image: UIImage) {
        guard let photo = Photo.create(from: image, in: context) else {
            showingPhotoError = true
            return
        }

        draftVehicle.photo = photo
    }

    private func loadSelectedImage(_ item: PhotosPickerItem?) async {
        guard let item, !Task.isCancelled else { return }

        defer {
            // An older or cancelled load must not clear a newer selection.
            if !Task.isCancelled, selectedImage == item {
                selectedImage = nil
            }
        }

        do {
            let data = try await item.loadTransferable(type: Data.self)
            try Task.checkCancellation()
            guard selectedImage == item else { return }

            guard let data, let image = UIImage(data: data) else {
                showingPhotoError = true
                return
            }

            setPhoto(from: image)
        } catch is CancellationError {
            // Cancelling an import is not an image failure.
        } catch {
            guard !Task.isCancelled, selectedImage == item else { return }
            showingPhotoError = true
        }
    }
}

#Preview {
    AddEditVehicleImageView(draftVehicle: DraftVehicle())
}
