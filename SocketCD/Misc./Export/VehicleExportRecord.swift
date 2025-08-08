//
//  VehicleExportRecord.swift
//  SocketCD
//
//  Created by Justin Risner on 8/7/25.
//

import Foundation

enum VehicleRecordType {
    case service(ServiceRecord)
    case repair(Repair)
}

// Used to unify all service records and repairs into a single record type, for use during export
struct VehicleExportRecord: Identifiable {
    let date: Date
    let odometer: Int
    let type: VehicleRecordType
    
    var id: UUID {
        switch self.type {
        case .service(let record):
            return record.id ?? UUID()
        case .repair(let record):
            return record.id ?? UUID()
        }
    }
}
