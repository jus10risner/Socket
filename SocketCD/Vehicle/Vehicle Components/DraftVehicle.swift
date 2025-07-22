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
    @Published var odometer: Int? = Int("")
    @Published var selectedColor: Color = Color(.socketPurple)
    @Published var photo: Photo?
    
    // Used when editing an existing vehicle
    init(vehicle: Vehicle) {
        id = vehicle.id
        name = vehicle.name
        odometer = vehicle.odometer
        selectedColor = vehicle.backgroundColor
        photo = vehicle.photo
    }
    
    // Used when adding a new vehicle
    init() { }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        name != "" && odometer != nil
    }
}
