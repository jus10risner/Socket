//
//  Photo+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

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
}
