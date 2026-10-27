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
    
    @Published var persistentStoreError: Error?

    // MARK: - Persistent container
    let container: NSPersistentCloudKitContainer
    private var categoryMaintenanceContext: NSManagedObjectContext?
    private var categoryChangeObserver: NSObjectProtocol?

    // MARK: - Preview instance
    static let preview: DataController = DataController(inMemory: true)

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

        if !inMemory {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.risner.justin.SocketCD"
            )
        }

        let maintenanceContext = container.newBackgroundContext()
        maintenanceContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        categoryMaintenanceContext = maintenanceContext
        categoryChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: nil
        ) { [weak self] _ in
            self?.maintainRepairCategories(seedIfEmpty: false)
        }

        // ✅ Load store synchronously so local data is immediately available
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.persistentStoreError = error
                }
                print("❌ Failed to load persistent store:", error)
            } else {
                print("✅ Loaded persistent store: \(storeDescription.url?.absoluteString ?? "")")
                DispatchQueue.main.async {
                    self.captureLegacyMeasurementUnitsIfNeeded()
                    self.maintainRepairCategories(seedIfEmpty: true)
                }
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

    private func captureLegacyMeasurementUnitsIfNeeded() {
        let context = container.viewContext
        let request = Vehicle.fetchRequest()

        guard let vehicles = try? context.fetch(request) else { return }

        let settings = AppSettingsStore.shared
        let legacyDistanceUnit = settings.distanceUnit
        let legacyVolumeUnit: VolumeUnits = switch settings.fuelEconomyUnit {
        case .mpg, .kmGal: .usGallons
        case .mpgImperial: .imperialGallons
        case .kmL, .L100km: .liters
        }

        for vehicle in vehicles {
            vehicle.captureLegacyMeasurementUnitsIfNeeded(
                distanceUnit: legacyDistanceUnit,
                volumeUnit: legacyVolumeUnit,
                fuelEconomyUnit: settings.fuelEconomyUnit
            )
        }

        save()
    }

    deinit {
        if let categoryChangeObserver {
            NotificationCenter.default.removeObserver(categoryChangeObserver)
        }
    }

    private func maintainRepairCategories(seedIfEmpty: Bool) {
        guard let context = categoryMaintenanceContext else { return }
        context.perform {
            // A dedicated serial context avoids saving or rolling back form drafts.
            context.reset()
            do {
                try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: seedIfEmpty)
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
                print("⚠️ Failed to reconcile repair categories: \(error.localizedDescription)")
            }
        }
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
