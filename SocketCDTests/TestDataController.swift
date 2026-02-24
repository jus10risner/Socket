//
//  TestDataController.swift
//  SocketCDTests
//
//  Created by Justin Risner on 2/24/26.
//

import CoreData

final class TestDataController {
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "SocketDataModel")
        
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load store: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
}
