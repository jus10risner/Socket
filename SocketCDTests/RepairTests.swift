//
//  RepairTests.swift
//  SocketCDTests
//
//  Created by Justin Risner on 2/27/26.
//

import CoreData
import Testing
@testable import SocketCD

struct RepairTests {
    @Test func `Empty store has no Repairs by default` () throws {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When - No action needed, since this tests for empty context
        
        // Then
        let repairs = try context.fetch(Repair.fetchRequest())
        
        #expect(repairs.isEmpty)
    }

    @Test func `Saving a Repair persists it to the context` () async throws {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let vehicle = Vehicle(context: context)
        vehicle.name = "Vehicle"
        vehicle.odometer = 10000
        
        let repair = Repair(context: context)
        repair.vehicle = vehicle
        repair.date = Date()
        repair.name = "Test Repair"
        repair.odometer = 12345
        
        do {
            try context.save()
        } catch let error {
            print("Error saving context: \(error)")
        }
        
        // Then
        let repairs = try context.fetch(Repair.fetchRequest())
        
        #expect(repairs.count == 1)
    }

    @Test func `Default values and property setters/getters` () throws {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let repair = Repair(context: context)
        
        // Defaults
        #expect(repair.date.timeIntervalSinceNow < 1) // Defaults to 'now'
        #expect(repair.name == "")
        #expect(repair.odometer == 0)
        #expect(repair.cost == 0)
        #expect(repair.note == "")
        #expect(repair.sortedPhotosArray.isEmpty)
        
        // Setters
        let testDate = Date()
        repair.date = testDate
        repair.name = "Brake Job"
        repair.odometer = 42000
        repair.note = "Replaced front pads"
        
        try context.save()
        
        // Then
        let fetchedRepair = try context.fetch(Repair.fetchRequest()).first!
        
        #expect(fetchedRepair.date == testDate)
        #expect(fetchedRepair.name == "Brake Job")
        #expect(fetchedRepair.odometer == 42000)
        #expect(fetchedRepair.note == "Replaced front pads")
    }

    @Test func `Cost property handles Double and nil` () throws {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let repair = Repair(context: context)
        repair.cost = 99.99
        
        // Then
        #expect(repair.cost == 99.99)
        
        repair.cost = nil // Setting nil should set cost to 0
        #expect(repair.cost == 0)
    }

    @Test func `sortedPhotosArray returns photos sorted by timeStamp ascending` () throws {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let repair = Repair(context: context)
        let photo1 = Photo(context: context)
        let photo2 = Photo(context: context)
        photo1.timeStamp = Date(timeIntervalSince1970: 100)
        photo2.timeStamp = Date(timeIntervalSince1970: 50)
        repair.photos = NSSet(array: [photo1, photo2])
        
        // Then
        let sorted = repair.sortedPhotosArray
        
        #expect(sorted.count == 2)
        #expect(sorted[0].timeStamp < sorted[1].timeStamp)
    }

    @Test func `updateAndSave updates all fields and saves context` () throws {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let vehicle = Vehicle(context: context)
        vehicle.name = "Car"
        vehicle.odometer = 5000
        
        let repair = Repair(context: context)
        repair.vehicle = vehicle
        
        let draft = DraftRepair()
        draft.date = Date(timeIntervalSince1970: 2222)
        draft.name = "Engine Mounts"
        draft.odometer = 6000
        draft.cost = 200
        draft.note = "Both mounts replaced"
        
        let p1 = Photo(context: context)
        let p2 = Photo(context: context)
        p1.timeStamp = Date(timeIntervalSince1970: 1)
        p2.timeStamp = Date(timeIntervalSince1970: 2)
        draft.photos = [p1, p2]
        
        repair.updateAndSave(draftRepair: draft)
        
        // Then
        #expect(repair.date == draft.date)
        #expect(repair.name == draft.name)
        #expect(repair.odometer == 6000)
        #expect(repair.cost == 200)
        #expect(repair.note == draft.note)
        #expect(repair.sortedPhotosArray.count == 2)
        #expect(repair.sortedPhotosArray[0].timeStamp < repair.sortedPhotosArray[1].timeStamp)
        #expect(vehicle.odometer == 6000)  // Vehicle odometer should be updated as well
    }

    @Test func `updateAndSave does not lower vehicle odometer` () throws {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let vehicle = Vehicle(context: context)
        vehicle.name = "Car"
        vehicle.odometer = 10000
        
        let repair = Repair(context: context)
        repair.vehicle = vehicle
        
        // Create draft with lower odometer
        let draft = DraftRepair()
        draft.date = Date.now
        draft.name = "Window Regulator"
        draft.odometer = 9000 // less than vehicle's odometer
        draft.cost = 75
        draft.note = "Fixed stuck window"
        draft.photos = []
        
        repair.updateAndSave(draftRepair: draft)
        
        // Then
        #expect(vehicle.odometer == 10000) // Vehicle odometer should remain unchanged
    }
}
