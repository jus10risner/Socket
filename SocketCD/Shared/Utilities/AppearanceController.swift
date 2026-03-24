//
//  AppearanceController.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

class AppearanceController {
    @ObservedObject var settings = AppSettings()
    static let shared = AppearanceController()
    
    var appearance: UIUserInterfaceStyle {
        switch settings.appAppearance {
        case .automatic:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    func setAppearance() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard let window = windowScene?.windows.first else { return }
        window.overrideUserInterfaceStyle = appearance
    }
}
