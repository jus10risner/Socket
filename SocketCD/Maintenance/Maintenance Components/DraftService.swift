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
    
    init(service: Service) {
        id = service.id
        name = service.name
        distanceInterval = service.distanceInterval
        timeInterval = service.timeInterval
        monthsInterval = service.monthsInterval
        serviceNote = service.note
    }
    
    init() {
        self.name = name
        self.distanceInterval = distanceInterval
        self.timeInterval = timeInterval
        self.monthsInterval = monthsInterval
        self.serviceNote = serviceNote
    }
    
    var canBeSaved: Bool {
        if name != "" && (distanceInterval != nil || timeInterval != nil) {
            return true
        } else {
            return false
        }
    }
}
