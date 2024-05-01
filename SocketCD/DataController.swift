//
//  DataController.swift
//  SocketCD
//
//  Created by Justin Risner on 3/12/24.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    // A singleton for the entire app to use
    static let shared = DataController()
    var isShowingDataError: Bool = false

    // A test configuration for SwiftUI previews
    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create example vehicle.
        let vehicle = Vehicle(context: viewContext)
        vehicle.name = "My Car"
        vehicle.odometer = Int.random(in: 10000...15000)
        vehicle.colorComponents = [0.34509801864624023, 0.3372548818588257, 0.8392157554626465, 1.0]

        return controller
    }()
    
    // A configuration, specifically for use in unit tests
    static let unitTest: DataController = {
        let controller = DataController(inMemory: true)
        // empty data store
        return controller
    }()
    
    // Storage for Core Data
    let container: NSPersistentContainer
//    let container: NSPersistentCloudKitContainer

    // An initializer to load Core Data, optionally able to use an in-memory store.
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SocketDataModel")
//        container = NSPersistentCloudKitContainer(name: "SocketDataModel")
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
//        container.viewContext.undoManager = UndoManager()

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                self.isShowingDataError = true
                print("Unresolved error: \(error.localizedDescription), \(error.userInfo)")
            }
        }
    }
    
    // If there are any changes, attempt to save
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                self.isShowingDataError = true
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
