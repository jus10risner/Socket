//
//  CoreDataDiagnosticTests.swift
//  SocketCDTests
//
//  Created by Justin Risner on 2/23/26.
//

import CoreData
import Testing
@testable import SocketCD

@Suite("Core Data diagnostics")
struct CoreDataDiagnosticsTests {
    @Test func `Model/Entity availability` () throws {
        let controller = DataController.unitTest
        let context = controller.container.viewContext

        // Verify the model contains your expected entity
        let model = context.persistentStoreCoordinator?.managedObjectModel
        let entityNames = model?.entities.map { $0.name ?? "" } ?? []
        #expect(entityNames.contains("Vehicle"), "Vehicle entity not found in loaded model. Entity names: \(entityNames)")
    }
}
