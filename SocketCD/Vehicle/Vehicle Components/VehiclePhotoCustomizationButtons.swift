//
//  VehiclePhotoCustomizationButtons.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import AVFoundation
import SwiftUI

struct VehiclePhotoCustomizationButtons: View {
    @Environment(\.managedObjectContext) var context
    let cameraManager = CameraManager()
    
    @Binding var inputImage: UIImage?
    @Binding var image: Image?
    @Binding var carPhoto: Photo?
    @Binding var selectedColor: Color
    
    @State private var showingImagePicker = false
    @State private var showingCameraAvailabilityAlert = false
    @State private var showingCameraAlert = false
    @State private var showingCameraCapture = false
    @State private var showingPhotoError = false
    
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
        .appropriateImagePickerModal(isPresented: $showingImagePicker, image: $inputImage, onDismiss: { loadImage() })
        .fullScreenCover(isPresented: $showingCameraCapture, onDismiss: { loadImage() }) {
            CameraCapture(image: $inputImage)
                .ignoresSafeArea()
        }
        .onChange(of: inputImage) { _ in verifyAndAdd() }
        .alert("No Camera Found", isPresented: $showingCameraAvailabilityAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This device does not appear to have a functioning camera.")
        }
        .alert("No Camera Access", isPresented: $showingCameraAlert) {
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
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showingImagePicker = true
            } label: {
                Label("Choose Photo", systemImage: "photo")
            }
            
            Button {
                Task {
                    await cameraManager.setUpCaptureSession(cameraAvailabilityAlert: &showingCameraAvailabilityAlert, cameraAccessAlert: &showingCameraAlert, cameraCapture: &showingCameraCapture)
                }
            } label: {
                Label("Take Photo", systemImage: "camera")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.selectedColor(for: .appTheme))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "photo")
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
                .fill(Color.selectedColor(for: .appTheme))
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
    
    // Loads the UIImage as a SwiftUI Image
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
    }
    
    // Verifies that an image has been selected, then converts it to binary data and saves to Core Data
    func verifyAndAdd() {
        if let selectedImage = inputImage {
            if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                let newPhoto = Photo(context: context)
                newPhoto.timeStamp_ = Date()
                newPhoto.imageData = imageData
                
                try? context.save()
                
                withAnimation {
                    carPhoto = newPhoto
                }
            }
        }
    }
}
