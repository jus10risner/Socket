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
    
    @State private var showingStoreError = false
    
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
                    // Reset the datastore to allow testing on-device
                    try? Tips.resetDatastore()
                    #endif

                    // Configure TipKit
                    try? Tips.configure()
                }
                .onReceive(dataController.$persistentStoreError) { error in
                    showingStoreError = (error != nil)
                }
                .alert("Unable to Load Data", isPresented: $showingStoreError) {
                    Button("Close Socket", role: .destructive) {
                        exit(EXIT_FAILURE)
                    }
                } message: {
                    Text(dataController.persistentStoreError?.localizedDescription ?? "Unknown error")
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            dataController.save()
            
            if newPhase == .active {
                Task {
                    await NotificationManager.shared.refreshAllNotifications() // Checks to see if any notifications need to be canceled or scheduled
                }
            }
        }
    }
}
