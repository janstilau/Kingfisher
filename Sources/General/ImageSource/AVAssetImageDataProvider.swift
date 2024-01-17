
#if !os(watchOS)

import Foundation
import AVKit

#if canImport(MobileCoreServices)
import MobileCoreServices
#else
import CoreServices
#endif

/// A data provider to provide thumbnail data from a given AVKit asset.
public struct AVAssetImageDataProvider: ImageDataProvider {

    /// The possible error might be caused by the `AVAssetImageDataProvider`.
    /// - userCancelled: The data provider process is cancelled.
    /// - invalidImage: The retrieved image is invalid.
    public enum AVAssetImageDataProviderError: Error {
        case userCancelled
        case invalidImage(_ image: CGImage?)
    }

    /// The asset image generator bound to `self`.
    public let assetImageGenerator: AVAssetImageGenerator

    /// The time at which the image should be generate in the asset.
    public let time: CMTime

    private var internalKey: String {
        guard let url = (assetImageGenerator.asset as? AVURLAsset)?.url else {
            return UUID().uuidString
        }
        return url.cacheKey
    }

    /// The cache key used by `self`.
    public var cacheKey: String {
        return "\(internalKey)_\(time.seconds)"
    }

    /// Creates an asset image data provider.
    /// - Parameters:
    ///   - assetImageGenerator: The asset image generator controls data providing behaviors.
    ///   - time: At which time in the asset the image should be generated.
    public init(assetImageGenerator: AVAssetImageGenerator, time: CMTime) {
        self.assetImageGenerator = assetImageGenerator
        self.time = time
    }

    /// Creates an asset image data provider.
    /// - Parameters:
    ///   - assetURL: The URL of asset for providing image data.
    ///   - time: At which time in the asset the image should be generated.
    ///
    /// This method uses `assetURL` to create an `AVAssetImageGenerator` object and calls
    /// the `init(assetImageGenerator:time:)` initializer.
    ///
    public init(assetURL: URL, time: CMTime) {
        let asset = AVAsset(url: assetURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        self.init(assetImageGenerator: generator, time: time)
    }

    /// Creates an asset image data provider.
    ///
    /// - Parameters:
    ///   - assetURL: The URL of asset for providing image data.
    ///   - seconds: At which time in seconds in the asset the image should be generated.
    ///
    /// This method uses `assetURL` to create an `AVAssetImageGenerator` object, uses `seconds` to create a `CMTime`,
    /// and calls the `init(assetImageGenerator:time:)` initializer.
    ///
    public init(assetURL: URL, seconds: TimeInterval) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        self.init(assetURL: assetURL, time: time)
    }

    public func data(handler: @escaping (Result<Data, Error>) -> Void) {
        assetImageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) {
            (requestedTime, image, imageTime, result, error) in
            if let error = error {
                handler(.failure(error))
                return
            }

            if result == .cancelled {
                handler(.failure(AVAssetImageDataProviderError.userCancelled))
                return
            }

            guard let cgImage = image, let data = cgImage.jpegData else {
                handler(.failure(AVAssetImageDataProviderError.invalidImage(image)))
                return
            }
            
            handler(.success(data))
        }
    }
}

extension CGImage {
    var jpegData: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0) else {
            return nil
        }
#if os(visionOS)
        guard let destination = CGImageDestinationCreateWithData(
            mutableData, UTType.jpeg.identifier as CFString , 1, nil
        ) else {
            return nil
        }
#else
        guard let destination = CGImageDestinationCreateWithData(mutableData, kUTTypeJPEG, 1, nil) else {
            return nil
        }
#endif
        
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

#endif
