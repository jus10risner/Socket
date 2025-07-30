//
//  DraftCustomInfo.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import Foundation

class DraftCustomInfo: ObservableObject {
    var id: UUID? = nil
    
    @Published var label: String = ""
    @Published var detail: String = ""
    @Published var note: String = ""
    @Published var photos: [Photo] = []
    
    // Initializes with an optional Custom Info, for use in add/edit context
    init(customInfo: CustomInfo? = nil) {
        if let customInfo {
            id = customInfo.id
            label = customInfo.label
            detail = customInfo.detail
            note = customInfo.note
            photos = customInfo.sortedPhotosArray
        }
    }
    
    // Determines whether the required information is present
    var canBeSaved: Bool {
        label != "" && (detail != "" || !photos.isEmpty)
    }
}
