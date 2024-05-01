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
    
    init(customInfo: CustomInfo) {
        id = customInfo.id
        label = customInfo.label
        detail = customInfo.detail
        note = customInfo.note
        photos = customInfo.sortedPhotosArray
    }
    
    init() {
        self.label = label
        self.detail = detail
        self.note = note
        self.photos = photos
    }
    
    var canBeSaved: Bool {
        if label != "" && (detail != "" || !photos.isEmpty) {
            return true
        } else {
            return false
        }
    }
}
