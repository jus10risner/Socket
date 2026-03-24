//
//  VehicleExportRecord.swift
//  SocketCD
//
//  Created by Justin Risner on 8/7/25.
//

import Foundation

enum VehicleRecordType {
    case serviceRecord(ServiceRecord)
    case serviceLog(ServiceLog)
    case repair(Repair)
}

// Used to unify all service records and repairs into a single record type, for use during export
struct VehicleExportRecord: Identifiable {
    let date: Date
    let odometer: Int
    let type: VehicleRecordType
    
    var id: UUID {
        switch self.type {
        case .serviceRecord(let record):
            return record.id ?? UUID()
        case .serviceLog(let log):
            return log.id ?? UUID()
        case .repair(let record):
            return record.id ?? UUID()
        }
    }
    
    var displayName: String {
        switch type {
        case .serviceRecord(let record):
            return record.service?.name ?? ""
        case .serviceLog(let log):
            return log.sortedServicesArray.map { $0.name }.joined(separator: ", ")
        case .repair(let repair):
            return repair.name
        }
    }
}
