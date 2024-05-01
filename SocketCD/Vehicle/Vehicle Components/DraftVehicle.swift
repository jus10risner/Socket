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
    
    init(vehicle: Vehicle) {
        id = vehicle.id
        name = vehicle.name
        odometer = vehicle.odometer
        selectedColor = vehicle.backgroundColor
        photo = vehicle.photo
    }
    
    init() {
        self.name = name
        self.odometer = odometer
        self.selectedColor = selectedColor
        self.photo = photo
    }
    
    var canBeSaved: Bool {
        if name != "" && odometer != nil {
            return true
        } else {
            return false
        }
    }
}
