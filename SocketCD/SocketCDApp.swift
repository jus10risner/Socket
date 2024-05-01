//
//  SocketCDApp.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import SwiftUI

@main
struct SocketCDApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var settings = AppSettings()
    let dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView(dataController: dataController)
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(settings)
                .task { AppearanceController.shared.setAppearance() }
                .onAppear {
                    
                    // Allows swiping to dismiss keyboard, for iOS 15; separate view modifier handles this for iOS 16+
                    UIScrollView.appearance().keyboardDismissMode = .interactive
                }
        }
        .onChange(of: scenePhase) { _ in
            dataController.save()
        }
    }
}
