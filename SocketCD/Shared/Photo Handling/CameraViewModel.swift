//
//  CameraViewModel.swift
//  SocketCD
//
//  Created by Justin Risner on 6/12/25.
//

import SwiftUI

@MainActor
class CameraViewModel: ObservableObject {
    @Published var showingCameraAccessAlert = false
    @Published var showingCameraUnavailableAlert = false
    @Published var showingCamera = false
    
    func requestCameraAccessAndAvailability() async {
        let authorized = await CameraManager.isAuthorized()
        
        if authorized {
            if CameraManager.isCameraAvailable() {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showingCamera = true
            } else {
                showingCameraUnavailableAlert = true
            }
        } else {
            showingCameraAccessAlert = true
        }
    }
}
