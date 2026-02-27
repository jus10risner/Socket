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
            #expect(service.serviceStatus == .due, "Service should be due if last log is within the service interval and within the alert range (from AppSettings)")
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
            #expect(service.serviceStatus == .overDue, "Service should be overdue if last log is outside the service interval (i.e. distance remaining < 0)")
        }
    }
    
    @Suite("Service Status By Time")
    struct ServiceStatusByTimeTests {
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
            #expect(service.serviceStatus == .due, "Service should be due if last log is within the service interval and within the alert range (from AppSettings)")
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
            #expect(service.serviceStatus == .overDue, "Service should be overdue if last log is outside the service interval (i.e. days remaining < 0)")
        }
    }
    
    @Suite("Service Status By Odometer And Time")
    struct ServiceStatusByOdometerAndTimeTests {
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
            #expect(service.serviceStatus == .overDue, "Service should be overdue if last log is outside the service interval (i.e. distance/days remaining < 0)")
        }
    }
    
    
    @Suite("Service Helper - Exhaustive Tests")
    struct ServiceHelperExhaustiveTests {
        @Test func `Default values and property setters/getters`() throws {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = Service(context: context)
            
            // Defaults
            #expect(service.name == "")
            #expect(service.distanceInterval == 0)
            #expect(service.timeInterval == 0)
            #expect(service.monthsInterval == true)
            #expect(service.note == "")
            #expect(service.notificationScheduled == false)
            #expect(service.distanceBasedNotificationIdentifier == "")
            #expect(service.timeBasedNotificationIdentifier == "")
            #expect(service.lastScheduledNotificationDate == nil)
            #expect(service.lastScheduledNotificationOdometer == nil)
            #expect(service.sortedServiceRecordsArray.isEmpty)
            
            // Setters
            service.name = "Test Service"
            service.distanceInterval = 8000
            service.timeInterval = 1
            service.monthsInterval = true
            service.note = "Every 8k miles"
            service.notificationScheduled = true
            service.distanceBasedNotificationIdentifier = "dist-id"
            service.timeBasedNotificationIdentifier = "time-id"
            
            let testDate = Date(timeIntervalSince1970: 10000)
            service.lastScheduledNotificationDate = testDate
            service.lastScheduledNotificationOdometer = 12000
            
            try context.save()
            
            // Then
            let fetched = try context.fetch(Service.fetchRequest()).first!
            #expect(fetched.name == "Test Service")
            #expect(fetched.distanceInterval == 8000)
            #expect(fetched.timeInterval == 1)
            #expect(fetched.monthsInterval == true)
            #expect(fetched.note == "Every 8k miles")
            #expect(fetched.notificationScheduled)
            #expect(fetched.distanceBasedNotificationIdentifier == "dist-id")
            #expect(fetched.timeBasedNotificationIdentifier == "time-id")
            #expect(fetched.lastScheduledNotificationDate == testDate)
            #expect(fetched.lastScheduledNotificationOdometer == 12000)
        }

        @Test func `lastScheduledNotificationOdometer handles nil and 0`() throws {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = Service(context: context)
            
            // Then
            service.lastScheduledNotificationOdometer = nil
            #expect(service.lastScheduledNotificationOdometer == nil)
            
            service.lastScheduledNotificationOdometer = 15000
            #expect(service.lastScheduledNotificationOdometer == 15000)
        }

        @Test func `sortedServiceRecordsArray sorts descending by date`() throws {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = Service(context: context)
            let r1 = ServiceRecord(context: context)
            let r2 = ServiceRecord(context: context)
            
            r1.date = Date(timeIntervalSince1970: 10)
            r2.date = Date(timeIntervalSince1970: 20)
            service.serviceRecords = NSSet(array: [r1, r2])
            
            // Then
            let sorted = service.sortedServiceRecordsArray
            
            #expect(sorted.count == 2)
            #expect(sorted[0].date > sorted[1].date)
        }

        @Test func `updateAndSave updates all fields and saves`() throws {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = Service(context: context)
            let draft = DraftService()
            draft.name = "Brake Flush"
            draft.distanceInterval = 20000
            draft.timeInterval = 2
            draft.monthsInterval = false
            draft.serviceNote = "Flush every 2 years"
            
            service.updateAndSave(draftService: draft)
            
            // Then
            #expect(service.name == "Brake Flush")
            #expect(service.distanceInterval == 20000)
            #expect(service.timeInterval == 2)
            #expect(service.monthsInterval == false)
            #expect(service.note == "Flush every 2 years")
        }

        @Test func `dateDue and odometerDue computed logic`() throws {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = Service(context: context)
            service.distanceInterval = 5000
            service.timeInterval = 12
            service.monthsInterval = true
            
            let r = ServiceRecord(context: context)
            let startDate = Date(timeIntervalSince1970: 1000)
            r.date = startDate
            r.odometer = 10000
            service.serviceRecords = NSSet(array: [r])
            
            // Then
            let expectedDate = Calendar.current.date(byAdding: .month, value: 12, to: startDate)
            #expect(service.dateDue?.timeIntervalSince1970 == expectedDate?.timeIntervalSince1970) // dateDue for monthsInterval
            #expect(service.odometerDue == 15000) // odometerDue
        }

        @Test func `intervalDescription pluralization and combination`() throws {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = Service(context: context)
            
            // Distance only
            service.distanceInterval = 6000
            service.timeInterval = 0
            #expect(service.intervalDescription.contains("6,000 mi"))
            
            // Time only, months
            service.distanceInterval = 0
            service.timeInterval = 6
            service.monthsInterval = true
            #expect(service.intervalDescription.contains("6 months"))
            
            // Time only, years
            service.timeInterval = 2
            service.monthsInterval = false
            #expect(service.intervalDescription.contains("2 years"))
            
            // Both
            service.distanceInterval = 4000
            service.timeInterval = 2
            #expect(service.intervalDescription.contains("4,000 mi"))
            #expect(service.intervalDescription.contains("2 years"))
        }

        @Test func `pluralize outputs correct singular and plural`() throws {
            // Given
            let controller = TestDataController()
            let context = controller.container.viewContext
            
            // When
            let service = Service(context: context)
            
            // Then
            #expect(service.pluralize(1, unit: "day") == "1 day")
            #expect(service.pluralize(2, unit: "day") == "2 days")
            #expect(service.pluralize(10, unit: "mile") == "10 miles")
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

