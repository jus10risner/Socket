//
//  DraftService.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import Foundation

class DraftService: ObservableObject {
    var id: UUID? = nil
    
    @Published var name: String = ""
    @Published var distanceInterval: Int? = nil
    @Published var timeInterval: Int? = nil
    @Published var monthsInterval: Bool = true
    @Published var serviceNote: String = ""
    
    // Initializes with an optional Service, for use in add/edit context
    init(service: Service? = nil) {
        if let service {
            id = service.id
            name = service.name
            distanceInterval = service.distanceInterval
            timeInterval = service.timeInterval
            monthsInterval = service.monthsInterval
            serviceNote = service.note
        }
    }
    
    // Determines whether a given field has a value that is not nil or 0
    private func hasValue(_ field: Int?) -> Bool {
        guard let v = field else { return false }
        return v != 0
    }

    // Determines whether the required information is present
    var canBeSaved: Bool {
        !name.isEmpty && (hasValue(distanceInterval) || hasValue(timeInterval))
    }
}
