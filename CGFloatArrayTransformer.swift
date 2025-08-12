//
//  CGFloatArrayTransformer.swift
//  SocketCD
//
//  Created by Justin Risner on 8/11/25.
//

import Foundation
import SwiftUI // for CGFloat

@objc(CGFloatArrayTransformer)
final class CGFloatArrayTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        
        let array: [CGFloat]
        
        if let cgFloatArray = value as? [CGFloat] {
            array = cgFloatArray
        } else if let numberArray = value as? [NSNumber] {
            array = numberArray.map { CGFloat(truncating: $0) }
        } else {
            // Unsupported type
            return nil
        }
        
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: false)
        } catch {
            print("Encoding error:", error)
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            // Try decoding as [CGFloat]
            if let array = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [CGFloat] {
                return array
            }
            // Or decoding as [NSNumber] fallback
            if let numberArray = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [NSNumber] {
                return numberArray.map { CGFloat(truncating: $0) }
            }
            return nil
        } catch {
            print("Decoding error:", error)
            return nil
        }
    }
}
