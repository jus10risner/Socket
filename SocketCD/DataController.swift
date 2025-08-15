//
//  DataController.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import CoreData
import CloudKit
import SwiftUI


final class DataController: ObservableObject {
    // MARK: - Shared instance
    static let shared = DataController()

    // MARK: - Persistent container
    let container: NSPersistentCloudKitContainer

    // MARK: - Preview / Unit Test instances
    static let preview: DataController = DataController(inMemory: true)

    static let unitTest: DataController = DataController(inMemory: true)

    // MARK: - Initializer
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "SocketDataModel")

        if inMemory {
            // Preview / unit test store
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if !inMemory, FileManager.default.ubiquityIdentityToken != nil {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.risner.justin.SocketCD"
            )
        } else if !inMemory {
            description.cloudKitContainerOptions = nil
            print("⚠️ CloudKit unavailable — using local store only")
        }

        // ✅ Load store synchronously so local data is immediately available
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            } else {
                print("✅ Loaded persistent store: \(storeDescription.url?.absoluteString ?? "")")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Async CloudKit schema initialization for debug
        #if DEBUG
        if description.cloudKitContainerOptions != nil {
            Task {
                do {
                    try container.initializeCloudKitSchema(options: [])
                    print("✅ CloudKit schema initialized")
                } catch {
                    print("❌ Unable to initialize CloudKit schema:", error)
                }
            }
        }
        #endif
    }

    // MARK: - Save / Delete
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print("⚠️ Failed to save Core Data context: \(error.localizedDescription)")
        }
    }

    func delete(_ object: NSManagedObject) {
        let context = container.viewContext
        context.delete(object)
        do {
            try context.save()
        } catch {
            print("❌ Failed to delete object:", error)
        }
    }
}

