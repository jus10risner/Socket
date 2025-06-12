//
//  CameraManager.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import AVFoundation
import SwiftUI

struct CameraManager {
    static func isAuthorized() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    static func isCameraAvailable() -> Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
//    var isAuthorized: Bool {
//        get async {
//            let status = AVCaptureDevice.authorizationStatus(for: .video)
//            
//            // Determine if the user previously authorized camera access.
//            var isAuthorized = status == .authorized
//            
//            // If the system hasn't determined the user's authorization status,
//            // explicitly prompt them for approval.
//            if status == .notDetermined {
//                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
//            }
//            
//            return isAuthorized
//        }
//    }
//    
//    @MainActor
//    func setUpCaptureSession(cameraAvailabilityAlert: inout Bool, cameraAccessAlert: inout Bool, cameraCapture: inout Bool) async {
////        guard await isAuthorized else { return }
//        if await isAuthorized {
//            if UIImagePickerController.isSourceTypeAvailable(.camera) {
//                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                cameraCapture = true
//            } else {
//                cameraAvailabilityAlert = true
//            }
//        } else {
//            cameraAccessAlert = true
//        }
//    }
    
    // TODO: Decide where to relocate this function, for better organization
    @MainActor
    func openSocketSettings() async {
        // Creates URL that links to Socket settings in the Settings app
        if let url = URL(string: UIApplication.openSettingsURLString) {
            
            // Takes the user to Socket settings
            await UIApplication.shared.open(url)
        }
    }
}
