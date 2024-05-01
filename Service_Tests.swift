//
//  Service_Tests.swift
//  SocketCDTests
//
//  Created by Justin Risner on 4/20/24.
//

import XCTest
@testable import SocketCD

final class Service_Tests: XCTestCase {
    
    let settings = AppSettings()
    var coreDataStack: DataController!
    
    override func setUp() async throws {
        coreDataStack = DataController(inMemory: true)
    }

    func test_Service_serviceStatus_shouldBeDue() {
        // Given
        let context = coreDataStack.container.viewContext
        
        // When
        for _ in 0..<100 {
            let vehicle = Vehicle(context: context)
            vehicle.name = "Car"
            vehicle.odometer = Int.random(in: 10000..<15000)
            
            // Tests odometer due
            let service = Service(context: context)
            service.vehicle = vehicle
            service.name = "Oil Change"
            service.distanceInterval = Int.random(in: settings.distanceBeforeMaintenance..<9000)
            
            let record = ServiceRecord(context: context)
            record.service = service
            record.date = Date()
            record.odometer = vehicle.odometer - Int.random(in: (service.distanceInterval - settings.distanceBeforeMaintenance)..<service.distanceInterval)
            
            // Tests date due
            let service2 = Service(context: context)
            service2.vehicle = vehicle
            service2.name = "Air Filter"
            service2.timeInterval = Int.random(in: 1..<12)
            service2.monthsInterval = Bool.random()
            
            let record2 = ServiceRecord(context: context)
            record2.service = service2
            let dateDue = Calendar.current.date(byAdding: .day, value: (settings.daysBeforeMaintenance), to: Date.now)
            record2.date = Calendar.current.date(byAdding: service2.monthsInterval ? .month : .year, value: -service2.timeInterval, to: dateDue!)!
            
            // Then
            XCTAssertTrue(service.serviceStatus == .due && service2.serviceStatus == .due)
            XCTAssertTrue(service.indicatorColor == .yellow && service2.indicatorColor == .yellow)
        }
    }
    
    func test_Service_serviceStatus_shouldBeOverdue() {
        // Given
        let context = coreDataStack.container.viewContext
        
        // When
        for _ in 0..<100 {
            let vehicle = Vehicle(context: context)
            vehicle.name = "Car"
            vehicle.odometer = Int.random(in: 10000..<15000)
            
            // Tests odometer due
            let service = Service(context: context)
            service.vehicle = vehicle
            service.name = "Oil Change"
            service.distanceInterval = Int.random(in: settings.distanceBeforeMaintenance..<9000)
            
            let record = ServiceRecord(context: context)
            record.service = service
            record.date = Date()
            record.odometer = vehicle.odometer - Int.random(in: (service.distanceInterval + 1)..<(service.distanceInterval + settings.distanceBeforeMaintenance))
            
            // Tests date due
            let service2 = Service(context: context)
            service2.vehicle = vehicle
            service2.name = "Air Filter"
            service2.timeInterval = Int.random(in: 1..<12)
            service2.monthsInterval = Bool.random()
            
            let record2 = ServiceRecord(context: context)
            record2.service = service2
            let dateDue = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)
            record2.date = Calendar.current.date(byAdding: service2.monthsInterval ? .month : .year, value: -service2.timeInterval, to: dateDue!)!
            
            // Then
            XCTAssertTrue(service.serviceStatus == .overDue && service2.serviceStatus == .overDue)
            XCTAssertTrue(service.indicatorColor == .red && service2.indicatorColor == .red)
        }
        
    }
    
    func test_Service_serviceStatus_shouldBeNotDue() {
        // Given
        let context = coreDataStack.container.viewContext
        
        // When
        for _ in 0..<100 {
            let vehicle = Vehicle(context: context)
            vehicle.name = "Car"
            vehicle.odometer = Int.random(in: 10000..<15000)
            
            // Tests odometer due
            let service = Service(context: context)
            service.vehicle = vehicle
            service.name = "Oil Change"
            service.distanceInterval = Int.random(in: (settings.distanceBeforeMaintenance + 1)..<9000)
            
            let record = ServiceRecord(context: context)
            record.service = service
            record.date = Date()
            record.odometer = vehicle.odometer - (service.distanceInterval - (settings.distanceBeforeMaintenance + 1))
            
            // Tests date due
            let service2 = Service(context: context)
            service2.vehicle = vehicle
            service2.name = "Air Filter"
            service2.timeInterval = Int.random(in: 1..<12)
            service2.monthsInterval = Bool.random()
            
            let record2 = ServiceRecord(context: context)
            record2.service = service2
            let dateDue = Calendar.current.date(byAdding: .day, value: (settings.daysBeforeMaintenance + Int.random(in: 5..<10)), to: Date.now)
            record2.date = Calendar.current.date(byAdding: service2.monthsInterval ? .month : .year, value: -service2.timeInterval, to: dateDue!)!
            
            // Then
            XCTAssertTrue(service.serviceStatus == .notDue && service2.serviceStatus == .notDue)
            XCTAssertTrue(service.indicatorColor == .green && service2.indicatorColor == .green)
        }
    }

}
