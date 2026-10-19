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

    @Test func `Recording odometer activity stores the actual log time`() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        let vehicle = Vehicle(context: context)
        let logTime = Date(timeIntervalSinceReferenceDate: 123_456)

        vehicle.recordOdometerActivity(at: logTime)
        try context.save()

        let savedVehicle = try #require(
            context.fetch(Vehicle.fetchRequest()).first
        )
        #expect(savedVehicle.lastOdometerLogAt == logTime)
    }

    @Test func `Baseline is excluded without hiding later service records or exports`() {
        let controller = TestDataController()
        let context = controller.container.viewContext
        let vehicle = Vehicle(context: context)
        let service = Service(context: context)
        service.vehicle = vehicle

        let baselineLog = ServiceLog(context: context)
        baselineLog.id = UUID()
        baselineLog.date = Date(timeIntervalSinceReferenceDate: 100)
        baselineLog.isBaseline = true

        let baselineRecord = ServiceRecord(context: context)
        baselineRecord.id = UUID()
        baselineRecord.date = baselineLog.date
        baselineRecord.service = service
        baselineRecord.serviceLog = baselineLog

        let firstVisibleLog = ServiceLog(context: context)
        firstVisibleLog.id = UUID()
        firstVisibleLog.date = Date(timeIntervalSinceReferenceDate: 200)

        let firstVisibleRecord = ServiceRecord(context: context)
        firstVisibleRecord.id = UUID()
        firstVisibleRecord.date = firstVisibleLog.date
        firstVisibleRecord.service = service
        firstVisibleRecord.serviceLog = firstVisibleLog

        let secondVisibleLog = ServiceLog(context: context)
        secondVisibleLog.id = UUID()
        secondVisibleLog.date = Date(timeIntervalSinceReferenceDate: 300)

        let secondVisibleRecord = ServiceRecord(context: context)
        secondVisibleRecord.id = UUID()
        secondVisibleRecord.date = secondVisibleLog.date
        secondVisibleRecord.service = service
        secondVisibleRecord.serviceLog = secondVisibleLog

        #expect(service.serviceHistoryRecordsArray == [secondVisibleRecord, firstVisibleRecord])
        #expect(vehicle.serviceAndRepairTimeline.count == 2)
        #expect(vehicle.groupedServiceAndRepairTimeline.flatMap(\.entries).count == 2)
    }
}
