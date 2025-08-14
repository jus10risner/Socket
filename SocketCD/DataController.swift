//
//  DataController.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import CoreData
import CloudKit
import SwiftUI

class DataController: ObservableObject {
    // MARK: - Singleton
    static let shared = DataController()
    
    // MARK: - Published container (optional until loaded)
    @Published private(set) var container: NSPersistentCloudKitContainer?
    
    // MARK: - Preview configuration
    static let preview: DataController = DataController(inMemory: true)
    
    static let unitTest: DataController = DataController(inMemory: true)
    
    // MARK: - Initializer
    init(inMemory: Bool = false) {
        Task { @MainActor in
            self.container = await Self.makePersistentContainer(inMemory: inMemory)
        }
    }
    
    // MARK: - Async container setup
    @MainActor
    private static func makePersistentContainer(inMemory: Bool = false) async -> NSPersistentCloudKitContainer {
        let container = NSPersistentCloudKitContainer(name: "SocketDataModel")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        if FileManager.default.ubiquityIdentityToken != nil {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.risner.justin.SocketCD"
            )
        } else {
            description.cloudKitContainerOptions = nil
            print("⚠️ CloudKit unavailable — using local store only")
        }
        
        await withCheckedContinuation { continuation in
            container.loadPersistentStores { storeDescription, error in
                if let error = error as NSError? {
                    print("❌ Persistent store failed to load:", error)
                } else {
                    print("✅ Persistent store loaded:", storeDescription.url?.absoluteString ?? "")
                }
                continuation.resume()
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        #if DEBUG
        if description.cloudKitContainerOptions != nil {
            do {
                try container.initializeCloudKitSchema(options: [])
            } catch {
                print("❌ Unable to initialize CloudKit schema:", error)
            }
        }
        #endif
        
        return container
    }
    
    // MARK: - Save / Delete
    func save() {
        guard let context = container?.viewContext else {
            print("⚠️ Core Data container not ready, skipping save")
            return
        }

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Log the error for debugging purposes
                print("⚠️ Failed to save Core Data context: \(error.localizedDescription)")
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        guard let context = container?.viewContext else { return }
        context.delete(object)
        do {
            try context.save()
        } catch {
            print("❌ Failed to delete object:", error)
        }
    }
}

