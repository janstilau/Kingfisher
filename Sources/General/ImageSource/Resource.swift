
import Foundation

/// Represents an image resource at a certain url and a given cache key.
/// Kingfisher will use a `Resource` to download a resource from network and cache it with the cache key when
/// using `Source.network` as its image setting source.

// Resource 这个抽象, 主要就是为了表现, 从网络下降过来的数据.
// 在 KF 里面, 各个接口都是面对的是抽象接口
// 在 Swfit 里面, 各个实体对象, 会实现这些抽象接口, 这种设计的好处是, 实现方用自己的设计, 而使用方则是直接使用原始的数据类型. 都没有负担.
public protocol Resource {
    
    /// The key used in cache.
    var cacheKey: String { get }
    
    /// The target image URL.
    var downloadURL: URL { get }
}

extension Resource {

    /// Converts `self` to a valid `Source` based on its `downloadURL` scheme. A `.provider` with
    /// `LocalFileImageDataProvider` associated will be returned if the URL points to a local file. Otherwise,
    /// `.network` is returned.
    
    // 各个数据类型, 应该主动的提供它相配合的数据类型之间的转化. 这在自己的工作里面, 也是经常会用到.
    public func convertToSource(overrideCacheKey: String? = nil) -> Source {
        let key = overrideCacheKey ?? cacheKey
        
        // 根据是否是 File, 这里会区分 provider 和 network.
        return downloadURL.isFileURL ?
            .provider(LocalFileImageDataProvider(fileURL: downloadURL, cacheKey: key)) :
            .network(KF.ImageResource(downloadURL: downloadURL, cacheKey: key))
    }
}

@available(*, deprecated, message: "This type conflicts with `GeneratedAssetSymbols.ImageResource` in Swift 5.9. Renamed to avoid issues in the future.", renamed: "KF.ImageResource")
public typealias ImageResource = KF.ImageResource


extension KF {
    /// ImageResource is a simple combination of `downloadURL` and `cacheKey`.
    /// When passed to image view set methods, Kingfisher will try to download the target
    /// image from the `downloadURL`, and then store it with the `cacheKey` as the key in cache.
    
    // Resource 的默认对象, 直接完成了对于 downloadURL, cacheKey 的存储.
    public struct ImageResource: Resource {

        // MARK: - Initializers

        /// Creates an image resource.
        ///
        /// - Parameters:
        ///   - downloadURL: The target image URL from where the image can be downloaded.
        ///   - cacheKey: The cache key. If `nil`, Kingfisher will use the `absoluteString` of `downloadURL` as the key.
        ///               Default is `nil`.
        public init(downloadURL: URL, cacheKey: String? = nil) {
            self.downloadURL = downloadURL
            self.cacheKey = cacheKey ?? downloadURL.cacheKey
        }

        // MARK: Protocol Conforming
        
        /// The key used in cache.
        public let cacheKey: String

        /// The target image URL.
        public let downloadURL: URL
    }
}

/// URL conforms to `Resource` in Kingfisher.
/// The `absoluteString` of this URL is used as `cacheKey`. And the URL itself will be used as `downloadURL`.
/// If you need customize the url and/or cache key, use `ImageResource` instead.

// 使用抽象接口, 一定要把原来想要抽象出来的数据类型, 进行相关的协议的实现.
// 不能影响到, 原有的数据类型的使用.
extension URL: Resource {
    public var cacheKey: String { return isFileURL ? localFileCacheKey : absoluteString }
    public var downloadURL: URL { return self }
}

extension URL {
    static let localFileCacheKeyPrefix = "kingfisher.local.cacheKey"
    
    // The special version of cache key for a local file on disk. Every time the app is reinstalled on the disk,
    // the system assigns a new container folder to hold the .app (and the extensions, .appex) folder. So the URL for
    // the same image in bundle might be different.
    //
    // This getter only uses the fixed part in the URL (until the bundle name folder) to provide a stable cache key
    // for the image under the same path inside the bundle.
    //
    // See #1825 (https://github.com/onevcat/Kingfisher/issues/1825)
    var localFileCacheKey: String {
        var validComponents: [String] = []
        for part in pathComponents.reversed() {
            validComponents.append(part)
            // 从后向前的顺序. 直到发现了标识.
            if part.hasSuffix(".app") || part.hasSuffix(".appex") {
                break
            }
        }
        // 然后给这个路径, 添加固定的前缀.
        // Self 这种, 是很常见的.
        let fixedPath = "\(Self.localFileCacheKeyPrefix)/\(validComponents.reversed().joined(separator: "/"))"
        if let q = query {
            return "\(fixedPath)?\(q)"
        } else {
            return fixedPath
        }
    }
}
