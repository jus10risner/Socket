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
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext

        // When
        // Verify the model contains the expected entity
        let model = context.persistentStoreCoordinator?.managedObjectModel
        let entityNames = model?.entities.map { $0.name ?? "" } ?? []
        
        // Then
        #expect(entityNames.contains("Vehicle"), "Vehicle entity not found in loaded model. Entity names: \(entityNames)")
    }
}
