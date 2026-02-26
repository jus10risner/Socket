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
    
    @Suite("Service Status By Odometer")
    struct ServiceStatusByOdometerTests {
        @Test func `Service status not due`() {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = createTestService(
                context: context,
                testingStatus: .notDue,
                testCase: .odometerOnly
            )
            
            // Then
            #expect(service.serviceStatus == .notDue, "Service should not be due if last log is within the service interval")
        }
        
        @Test func `Service status due` () {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = createTestService(
                context: context,
                testingStatus: .due,
                testCase: .odometerOnly
            )
            
            // Then
            #expect(service.serviceStatus == .due, "Service should not be due if last log is within the service interval")
        }
        
        @Test func `Service status overDue` () {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = createTestService(
                context: context,
                testingStatus: .overDue,
                testCase: .odometerOnly
            )
            
            // Then
            #expect(service.serviceStatus == .overDue, "Service should not be due if last log is within the service interval")
        }
    }
    
    @Suite("Service Status By Time")
    struct ServiceByTimeTests {
        @Test func `Service status not due`() {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = createTestService(
                context: context,
                testingStatus: .notDue,
                testCase: .timeOnly
            )
            
            // Then
            #expect(service.serviceStatus == .notDue, "Service should not be due if last log is within the service interval")
        }
        
        @Test func `Service status due` () {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = createTestService(
                context: context,
                testingStatus: .due,
                testCase: .timeOnly
            )
            
            // Then
            #expect(service.serviceStatus == .due, "Service should not be due if last log is within the service interval")
        }
        
        @Test func `Service status overDue` () {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = createTestService(
                context: context,
                testingStatus: .overDue,
                testCase: .timeOnly
            )
            
            // Then
            #expect(service.serviceStatus == .overDue, "Service should not be due if last log is within the service interval")
        }
    }
    
    @Suite("Service Status By Odometer And Time")
    struct ServiceByOdometerAndTimeTests {
        @Test func `Service status should be not due`() {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = createTestService(
                context: context,
                testingStatus: .notDue,
                testCase: .both
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
                testingStatus: .due,
                testCase: .both
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
                testingStatus: .overDue,
                testCase: .both
            )
            
            // Then
            #expect(service.serviceStatus == .overDue, "Service should be overdue if last log is outside the service interval (i.e. days/time remaining < 0)")
        }
    }
}

// Returns a service containing a service log, using the provided testingStatus and testCase values
private func createTestService(context: NSManagedObjectContext, testingStatus: ServiceStatus, testCase: TestCase) -> Service {
    let odometer = 10000
    let distanceInterval = 5000
    let timeInterval = 12
    
    let vehicle = Vehicle(context: context)
    vehicle.name = "Vehicle"
    vehicle.odometer = odometer
    
    let service = Service(context: context)
    service.vehicle = vehicle
    service.name = "Oil Change"
    service.distanceInterval = distanceInterval
    service.timeInterval = timeInterval
    service.monthsInterval = true
    
    // Create a ServiceLog for the last performed service, using testingStatus and testCase to set date and odometer values
    let log = ServiceLog(context: context)
    
    log.date = {
        switch (testingStatus, testCase) {
        case (.notDue, .odometerOnly):
            return Date()
            
        case (.notDue, .timeOnly), (.notDue, .both):
            // Not due: logged more recently than the due warning window
            let notDueDate = Calendar.current.date(byAdding: .month, value: -timeInterval, to: Date())!
            return Calendar.current.date(byAdding: .day, value: 15, to: notDueDate)!
            
        case (.due, .odometerOnly):
            return Date()
            
        case (.due, .timeOnly), (.due, .both):
            // Due: logged exactly at the due warning window
            let dueDate = Calendar.current.date(byAdding: .month, value: -timeInterval, to: Date())!
            return Calendar.current.date(byAdding: .day, value: 14, to: dueDate)!
            
        case (.overDue, .odometerOnly):
            return Date()
            
        case (.overDue, .timeOnly), (.overDue, .both):
            // Overdue: logged just past the time interval
            let overDueDate = Calendar.current.date(byAdding: .month, value: -timeInterval, to: Date())!
            return Calendar.current.date(byAdding: .day, value: -1, to: overDueDate)!
        }
    }()
    
    log.odometer = {
        switch (testingStatus, testCase) {
        case (.notDue, .odometerOnly):
            return odometer
        case (.notDue, .timeOnly):
            return odometer
        case (.notDue, .both):
            return odometer
            
        case (.due, .odometerOnly):
            return odometer - (distanceInterval - 500)
        case (.due, .timeOnly):
            return odometer
        case (.due, .both):
            return odometer - (distanceInterval - 500)
            
        case (.overDue, .odometerOnly):
            return odometer - (distanceInterval + 1)
        case (.overDue, .timeOnly):
            return odometer
        case (.overDue, .both):
            return odometer - (distanceInterval + 1)
        }
    }()
    
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

// Used when creating service logs, to switch on the values used for calculating service status
private enum TestCase {
    case odometerOnly, timeOnly, both
}
