//
//  CustomInfo+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import Foundation

extension CustomInfo {
    
    var label: String {
        get { label_ ?? "" }
        set { label_ = newValue }
    }
    
    var detail: String {
        get { detail_ ?? "" }
        set { detail_ = newValue }
    }
    
    var note: String {
        get { note_ ?? "" }
        set { note_ = newValue }
    }
    
    var sortedPhotosArray: [Photo] {
        let set = photos as? Set<Photo> ?? []
        
        return set.sorted {
            $0.timeStamp < $1.timeStamp
        }
        
    }
    
    // MARK: - CRUD Methods
    
    func updateAndSave(draftCustomInfo: DraftCustomInfo) {
        let context = DataController.shared.container.viewContext
        
        self.label = draftCustomInfo.label
        self.detail = draftCustomInfo.detail
        self.note = draftCustomInfo.note
        self.photos = NSSet(array: draftCustomInfo.photos)
        
        try? context.save()
    }
}
