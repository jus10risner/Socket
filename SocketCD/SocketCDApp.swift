//
//  SocketCDApp.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import CloudKit
import SwiftUI
import TipKit

@main
struct SocketCDApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var settings = AppSettings()
    let dataController = DataController.shared
    
    init() {
        _ = NotificationObserver.shared // Start observing right away
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(settings.selectedAccent())
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(settings)
                .task {
                    AppearanceController.shared.setAppearance()
                    
                    #if DEBUG
                    // Reset the datastore for testing purposes
                    try? Tips.resetDatastore()
                    #endif

                    // Configure TipKit
                    try? Tips.configure()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            dataController.save()
            
            if newPhase == .active {
                Task {
                    await NotificationManager.shared.refreshAllNotifications()
                }
            }
        }
    }
}
