//
//  VehiclePhotoCustomizationButtons.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import AVFoundation
import PhotosUI
import SwiftUI

struct VehiclePhotoCustomizationButtons: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.managedObjectContext) var context
    @StateObject private var cameraViewModel = CameraViewModel()
    let cameraManager = CameraManager()
    
    @Binding var carPhoto: Photo?
    @Binding var selectedColor: Color
    
    @State private var showingPhotosPicker = false
    @State private var showingPhotoError = false
    
    @State var capturedImage: UIImage?
    @State private var selectedImage: PhotosPickerItem?
    
    var body: some View {
        imageAndColorSelectButtons
    }
    
    
    // MARK: - Views
    
    private var imageAndColorSelectButtons: some View {
        HStack {
            Spacer()
            
            imageSelectButton
            
            if carPhoto == nil {
                Spacer()
                
                colorSelectButton
            }
            
            Spacer()
        }
        .padding(.top, 5)
        .animation(.default, value: carPhoto)
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
                    await cameraManager.openSocketSettings()
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
    
    // Menu that allows user to choose a photo from their Photo Library, or take a photo with their phone's camera
    private var imageSelectButton: some View {
        Menu {
            Button {
//                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            ZStack {
                Circle()
                    .fill(settings.accentColor(for: .appTheme))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "camera.fill")
                    .padding(8)
                    .foregroundStyle(Color.white)
            }
            .fixedSize()
            .accessibilityLabel("Add Vehicle Photo")
        }
        .buttonStyle(.plain)
    }
    
    // Button that allows user to select a background color, in lieu of adding a vehicle photo
    private var colorSelectButton: some View {
        ZStack {
            Circle()
                .fill(settings.accentColor(for: .appTheme))
                .frame(width: 40, height: 40)
            
            Image(systemName: "paintbrush.fill")
                .padding(8)
                .foregroundStyle(Color.white)
        }
        .fixedSize()
        .accessibilityElement()
        .accessibilityLabel("Select Background Color. Button.")
        .accessibilityHint("Change the color of the vehicle graphic, instead of adding a photo")
        
        // Allows custom button for opening ColorPicker
        .overlay(
            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .scaleEffect(CGSize(width: 1.5, height: 1.5))
                .labelsHidden()
                .opacity(0.015)
                .accessibilityHidden(true)
        )
    }
    
    
    // MARK: - Methods
    
    // Verifies that a valid image has been captured via the camera, then converts it to binary data
    private func verifyAndAdd() {
        Task {
            if let capturedImage {
                let newPhoto = Photo.create(from: capturedImage, in: context)
                
                withAnimation {
                    carPhoto = newPhoto
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
                    carPhoto = newPhoto
                }
                
                self.selectedImage = nil
            }
        }
    }
}
