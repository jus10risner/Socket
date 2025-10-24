//
//  CameraCapture.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import AVFoundation
import SwiftUI

// credit: https://designcode.io/swiftui-advanced-handbook-imagepicker
// Required for camera capture

struct CameraCapture: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraCapture>) -> UIImagePickerController {
        let cameraCapture = UIImagePickerController()
        cameraCapture.allowsEditing = false
        cameraCapture.sourceType = .camera
        cameraCapture.delegate = context.coordinator
        
        return cameraCapture
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        var parent: CameraCapture

        init(_ parent: CameraCapture) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
