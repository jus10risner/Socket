//
//  ServiceContext.swift
//  SocketCD
//
//  Created by Justin Risner on 7/18/25.
//

import SwiftUI

struct ServiceContext {
    let service: Service
    let currentDate: Date = Date()
    let currentOdometer: Int

    var daysUntilDue: Int? {
        guard let dateDue = service.dateDue else { return nil }
        return Calendar.current.dateComponents([.day], from: currentDate, to: dateDue).day
    }

    var milesUntilDue: Int? {
        guard let odometerDue = service.odometerDue else { return nil }
        return odometerDue - currentOdometer
    }
}
