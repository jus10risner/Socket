//
//  PhotoImageLoader.swift
//  SocketCD
//

import ImageIO
import SwiftUI

actor PhotoImageLoader {
    static let shared = PhotoImageLoader()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.totalCostLimit = 128 * 1_024 * 1_024
        cache.countLimit = 40
    }

    func image(
        forKey key: String,
        data: Data,
        maximumPixelSize: CGFloat
    ) -> UIImage? {
        let cacheKey = "\(key)-\(Int(maximumPixelSize))" as NSString

        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard let image = Self.downsampledImage(
            from: data,
            maximumPixelSize: maximumPixelSize
        ) else {
            return nil
        }

        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: cacheKey, cost: cost)
        return image
    }

    private static func downsampledImage(
        from data: Data,
        maximumPixelSize: CGFloat
    ) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return nil
        }

        return UIImage(cgImage: image)
    }
}

struct CachedPhotoImage: View {
    let photo: Photo
    let maximumPixelSize: CGFloat
    let contentMode: ContentMode

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.clear
            }
        }
        .task(id: photo.objectID) {
            let photoID = photo.objectID
            let data = photo.imageData
            let key = photoID.uriRepresentation().absoluteString

            image = nil
            let loadedImage = await PhotoImageLoader.shared.image(
                forKey: key,
                data: data,
                maximumPixelSize: maximumPixelSize
            )

            guard !Task.isCancelled, photo.objectID == photoID else { return }
            image = loadedImage
        }
    }
}

enum PhotoDataProcessor {
    nonisolated static func jpegData(from data: Data) -> Data? {
        autoreleasepool {
            UIImage(data: data)?.jpegData(compressionQuality: 0.8)
        }
    }
}
