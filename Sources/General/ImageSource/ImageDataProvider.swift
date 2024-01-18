
import Foundation

/// Represents a data provider to provide image data to Kingfisher when setting with
/// `Source.provider` source. Compared to `Source.network` member, it gives a chance
/// to load some image data in your own way, as long as you can provide the data
/// representation for the image.
// 使用自己的方式, 记性图片的加载. 这个方式, 主要就是实现了 func data(handler: @escaping (Result<Data, Error>) -> Void)
// 所以实际上这里也是可以使用异步的方式进行获取.
public protocol ImageDataProvider {
    
    /// The key used in cache.
    var cacheKey: String { get }
    
    /// Provides the data which represents image. Kingfisher uses the data you pass in the
    /// handler to process images and caches it for later use.
    
    // 统一使用了回调的方式, 来进行数据的返回.
    /// - Parameter handler: The handler you should call when you prepared your data.
    ///                      If the data is loaded successfully, call the handler with
    ///                      a `.success` with the data associated. Otherwise, call it
    ///                      with a `.failure` and pass the error.
    ///
    /// - Note:
    /// If the `handler` is called with a `.failure` with error, a `dataProviderError` of
    /// `ImageSettingErrorReason` will be finally thrown out to you as the `KingfisherError`
    /// from the framework.
    func data(handler: @escaping (Result<Data, Error>) -> Void)

    /// The content URL represents this provider, if exists.
    var contentURL: URL? { get }
}

public extension ImageDataProvider {
    var contentURL: URL? { return nil }
    func convertToSource() -> Source {
        .provider(self)
    }
}

/*
 作为一个类库, 需要提供一些基本的实现类, 来完成自己抽象的实现. 
 */

/// Represents an image data provider for loading from a local file URL on disk.
/// Uses this type for adding a disk image to Kingfisher. Compared to loading it
/// directly, you can get benefit of using Kingfisher's extension methods, as well
/// as applying `ImageProcessor`s and storing the image to `ImageCache` of Kingfisher.
public struct LocalFileImageDataProvider: ImageDataProvider {

    // MARK: Public Properties

    /// The file URL from which the image be loaded.
    public let fileURL: URL
    private let loadingQueue: ExecutionQueue

    // MARK: Initializers

    /// Creates an image data provider by supplying the target local file URL.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL from which the image be loaded.
    ///   - cacheKey: The key is used for caching the image data. By default,
    ///               the `absoluteString` of `fileURL` is used.
    ///   - loadingQueue: The queue where the file loading should happen. By default, the dispatch queue of
    ///                   `.global(qos: .userInitiated)` will be used.
    public init(
        fileURL: URL,
        cacheKey: String? = nil,
        loadingQueue: ExecutionQueue = .dispatch(DispatchQueue.global(qos: .userInitiated))
    ) {
        self.fileURL = fileURL
        self.cacheKey = cacheKey ?? fileURL.localFileCacheKey
        self.loadingQueue = loadingQueue
    }

    // MARK: Protocol Conforming

    /// The key used in cache.
    public var cacheKey: String

    // 直接是就是使用 fileURL 的读取.
    // 要习惯使用 Result. 
    public func data(handler:@escaping (Result<Data, Error>) -> Void) {
        loadingQueue.execute {
            handler(Result(catching: { try Data(contentsOf: fileURL) }))
        }
    }
    
    #if swift(>=5.5)
    #if canImport(_Concurrency)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public var data: Data {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                // 还是使用 loadingQueue.execute , 不过不是用 handler 的方法回传了, 而是使用 continuation 的方式.
                loadingQueue.execute {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        continuation.resume(returning: data)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    #endif
    #endif

    /// The URL of the local file on the disk.
    public var contentURL: URL? {
        return fileURL
    }
}

/// Represents an image data provider for loading image from a given Base64 encoded string.
public struct Base64ImageDataProvider: ImageDataProvider {

    // MARK: Public Properties
    /// The encoded Base64 string for the image.
    // Base64 这种方式, 还是经常使用到的.
    public let base64String: String

    // MARK: Initializers

    /// Creates an image data provider by supplying the Base64 encoded string.
    ///
    /// - Parameters:
    ///   - base64String: The Base64 encoded string for an image.
    ///   - cacheKey: The key is used for caching the image data. You need a different key for any different image.
    public init(base64String: String, cacheKey: String) {
        self.base64String = base64String
        self.cacheKey = cacheKey
    }

    // MARK: Protocol Conforming

    /// The key used in cache.
    public var cacheKey: String

    // base64 的解析, 数据都在本地, 直接就是 handler 的调用了.
    public func data(handler: (Result<Data, Error>) -> Void) {
        let data = Data(base64Encoded: base64String)!
        handler(.success(data))
    }
}

/// Represents an image data provider for a raw data object.
// 最彻底的方式, 直接就是使用了 Image Data.
public struct RawImageDataProvider: ImageDataProvider {

    // MARK: Public Properties

    /// The raw data object to provide to Kingfisher image loader.
    public let data: Data

    // MARK: Initializers

    /// Creates an image data provider by the given raw `data` value and a `cacheKey` be used in Kingfisher cache.
    ///
    /// - Parameters:
    ///   - data: The raw data reprensents an image.
    ///   - cacheKey: The key is used for caching the image data. You need a different key for any different image.
    public init(data: Data, cacheKey: String) {
        self.data = data
        self.cacheKey = cacheKey
    }

    // MARK: Protocol Conforming
    
    /// The key used in cache.
    public var cacheKey: String

    public func data(handler: @escaping (Result<Data, Error>) -> Void) {
        handler(.success(data))
    }
}
