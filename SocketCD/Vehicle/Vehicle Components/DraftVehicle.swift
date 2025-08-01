//
//  DraftVehicle.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import SwiftUI

class DraftVehicle: ObservableObject {
    var id: UUID? = nil
    
    @Published var name: String = ""
    @Published var odometer: Int? = nil
    @Published var selectedColor: Color = Color(.socketPurple)
    @Published var photo: Photo?
    
    // Initializes with an optional Vehicle, for use in add/edit context
    init(vehicle: Vehicle? = nil) {
        if let vehicle {
            id = vehicle.id
            name = vehicle.name
            odometer = vehicle.odometer
            selectedColor = vehicle.backgroundColor
            photo = vehicle.photo
        }
    }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        name != "" && odometer != nil
    }
}
