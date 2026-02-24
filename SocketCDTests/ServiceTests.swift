//
//  ServiceTests.swift
//  SocketCDTests
//
//  Created by Justin Risner on 2/23/26.
//

import CoreData
import Testing
@testable import SocketCD

@Suite("Service Tests")
struct ServiceTests {
    @Test func `Service status should be not due`() {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let service = createTestService(
            context: context,
            logDate: Calendar.current.date(byAdding: .month, value: -3, to: Date.now) ?? Date.now,
            logOdometer: 7500
        )
        
        // Then
        #expect(service.serviceStatus == .notDue, "Service should not be due if last log is within the service interval")
    }
    
    @Test func `Service status should be due` () {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let service = createTestService(
            context: context,
            logDate: Calendar.current.date(byAdding: .month, value: -11, to: Date.now) ?? Date.now,
            logOdometer: 5200
        )
        
        // Then
        #expect(service.serviceStatus == .due, "Service should be due if last log is within the service interval and within the alert range (from AppSettings)")
    }
    
    @Test func `Service status should be overdue` () {
        // Given
        let controller = TestDataController()
        let context = controller.container.viewContext
        
        // When
        let service = createTestService(
            context: context,
            logDate: Calendar.current.date(byAdding: .month, value: -12, to: Date.now) ?? Date.now,
            logOdometer: 4900
        )
        
        // Then
        #expect(service.serviceStatus == .overDue, "Service should be overdue if last log is outside the service interval (i.e. days/time remaining < 0)")
    }
}

// Returns a service containing a service log, using the provided logDate and logOdometer values
private func createTestService(context: NSManagedObjectContext, logDate: Date, logOdometer: Int) -> Service {
    let vehicle = Vehicle(context: context)
    vehicle.name = "Test Vehicle"
    vehicle.odometer = 10000
    
    let service = Service(context: context)
    service.vehicle = vehicle
    service.name = "Oil Change"
    service.distanceInterval = 5000
    service.timeInterval = 1 // 1 year
    service.monthsInterval = false
    
    // Create a ServiceLog for the last performed service
    let log = ServiceLog(context: context)
    log.date = logDate
    log.odometer = logOdometer
    
    // Create a record connecting the log to the service
    let record = ServiceRecord(context: context)
    record.service = service
    record.serviceLog = log
    record.date = log.date
    record.odometer = log.odometer
    
    do {
        try context.save()
    } catch let error {
        print("Error saving context: \(error)")
    }
    
    return service
}
