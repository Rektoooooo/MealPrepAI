import UIKit
import ImageIO

/// Shared cache for downsampled recipe images.
/// Keyed by "\(recipeId)-\(maxDimension)" to avoid re-decoding on every SwiftUI body evaluation.
let downsampledImageCache: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.countLimit = 150
    cache.totalCostLimit = 50 * 1024 * 1024 // ~50 MB
    return cache
}()

extension UIImage {
    /// Efficiently downsample image data using ImageIO to avoid
    /// decoding the full-resolution bitmap into memory.
    static func downsample(data: Data, maxDimension: CGFloat) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else { return nil }
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension * UIScreen.main.scale
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Cached downsample: returns a previously decoded image if available,
    /// otherwise downsamples and stores the result in `downsampledImageCache`.
    static func cachedDownsample(data: Data, recipeId: UUID, maxDimension: CGFloat) -> UIImage? {
        let key = "\(recipeId)-\(Int(maxDimension))" as NSString
        if let cached = downsampledImageCache.object(forKey: key) {
            return cached
        }
        guard let image = downsample(data: data, maxDimension: maxDimension) ?? UIImage(data: data) else {
            return nil
        }
        downsampledImageCache.setObject(image, forKey: key)
        return image
    }
}
