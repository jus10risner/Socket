//
//  VehicleTests.swift
//  SocketCDTests
//
//  Created by Justin Risner on 2/23/26.
//

import CoreData
import Testing
@testable import SocketCD

@Suite("Vehicle Tests")
struct VehicleTests {
    @Test func `Empty store has no vehicles by default` () throws {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let vehicles = try context.fetch(Vehicle.fetchRequest())
        
        // Then
        #expect(vehicles.count == 0, "Expected zero vehicles in a fresh in-memory store, found \(vehicles.count)")
    }
    
    @Test func `Saving a Vehicle persists it to the context` () {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let vehicle = Vehicle(context: context)
        vehicle.name = "Test"
        vehicle.odometer = 12345
        
        do {
            try context.save()
        } catch let error {
            print( "Error saving context: \(error)")
        }
        
        // Then
        do {
            let vehicles = try context.fetch(Vehicle.fetchRequest())
            #expect(vehicles.count == 1)
        } catch let error {
            print("Error fetching vehicles: \(error)")
        }
    }
}
