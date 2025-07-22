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
    @Published var distanceInterval: Int? = Int("")
    @Published var timeInterval: Int? = Int("")
    @Published var monthsInterval: Bool = true
    @Published var serviceNote: String = ""
    
    // Used when editing an existing service
    init(service: Service) {
        id = service.id
        name = service.name
        distanceInterval = service.distanceInterval
        timeInterval = service.timeInterval
        monthsInterval = service.monthsInterval
        serviceNote = service.note
    }
    
    // Used when creating a new service
    init() { }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        name != "" && (distanceInterval != nil || timeInterval != nil)
    }
}
