
import Foundation

/// Represents an image setting source for Kingfisher methods.
///
/// A `Source` value indicates the way how the target image can be retrieved and cached.
///
/// - network: The target image should be got from network remotely. The associated `Resource`
///            value defines detail information like image URL and cache key.
/// - provider: The target image should be provided in a data format. Normally, it can be an image
///             from local storage or in any other encoding format (like Base64).
/*
 /// 代表 Kingfisher 方法中的图像设置来源。
 ///
 /// `Source` 值表示获取和缓存目标图像的方式。
 ///
 /// - network: 目标图像应该从远程网络获取。关联的 `Resource` 值定义了详细信息，如图像 URL 和缓存键。
 /// - provider: 目标图像应以数据格式提供。通常，它可以是来自本地存储的图像或任何其他编码格式（如 Base64）
 */
public enum Source {

    /// Represents the source task identifier when setting an image to a view with extension methods.
    // 在 Swift 里面, 没有 static 这样的全局量存在, 所以要做这件事, 需要使用一个 Enum 进行包装.
    // 这个类型, 又在 Source 的作用域下面, 这样通过类作用域调用这些函数.
    public enum Identifier {

        /// The underlying value type of source identifier.
        public typealias Value = UInt
        static private(set) var current: Value = 0
        static func next() -> Value {
            current += 1
            return current
        }
    }

    // MARK: Member Cases

    // 使用 Enum 当盒子使用的案例. 里面所有的内容, 都不是具体的类型, 而是 Protocol.
    
    /// The target image should be got from network remotely. The associated `Resource`
    /// value defines detail information like image URL and cache key.
    // 从网络获取数据
    case network(Resource)
    
    /// The target image should be provided in a data format. Normally, it can be an image
    /// from local storage or in any other encoding format (like Base64).
    // 应该是本地就有这份数据. 
    case provider(ImageDataProvider)

    // MARK: Getting Properties

    /// The cache key defined for this source value.
    public var cacheKey: String {
        switch self {
        case .network(let resource): return resource.cacheKey
        case .provider(let provider): return provider.cacheKey
        }
    }

    /// The URL defined for this source value.
    ///
    /// For a `.network` source, it is the `downloadURL` of associated `Resource` instance.
    /// For a `.provider` value, it is always `nil`.
    public var url: URL? {
        switch self {
        case .network(let resource): return resource.downloadURL
        case .provider(let provider): return provider.contentURL
        }
    }
}

// 对于 Enum 来说, 根据 Case 的不同, 进行分别处理, 是一个非常非常普遍的行为.
extension Source: Hashable {
    public static func == (lhs: Source, rhs: Source) -> Bool {
        switch (lhs, rhs) {
        case (.network(let r1), .network(let r2)):
            return r1.cacheKey == r2.cacheKey && r1.downloadURL == r2.downloadURL
        case (.provider(let p1), .provider(let p2)):
            return p1.cacheKey == p2.cacheKey && p1.contentURL == p2.contentURL
        case (.provider(_), .network(_)):
            return false
        case (.network(_), .provider(_)):
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .network(let r):
            hasher.combine(r.cacheKey)
            hasher.combine(r.downloadURL)
        case .provider(let p):
            hasher.combine(p.cacheKey)
            hasher.combine(p.contentURL)
        }
    }
}

extension Source {
    // 这种, as 开头的写法, 是非常常见的. 
    var asResource: Resource? {
        guard case .network(let resource) = self else {
            return nil
        }
        return resource
    }
}
