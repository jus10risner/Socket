//
//  Photo+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import CoreData
import SwiftUI

extension Photo {
    
    var timeStamp: Date {
        get { timeStamp_ ?? Date() }
        set { timeStamp_ = newValue }
    }
    
    var imageData: Data {
        get { imageData_ ?? Data() }
        set { imageData_ = newValue }
    }
    
    var converted: UIImage {
        UIImage(data: imageData)!
    }
    
    
    // MARK: - CRUD Methods
    
    static func create(from uiImage: UIImage, in context: NSManagedObjectContext) -> Photo? {
        guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else { return nil }
        
        let photo = Photo(context: context)
        photo.id = UUID()
        photo.timeStamp = Date()
        photo.imageData = imageData
        return photo
    }
}
