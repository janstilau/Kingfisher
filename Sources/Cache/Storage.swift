
import Foundation

// 这里面,

/// Constants for some time intervals
// 使用一个专门的类型, 或者作用域, 存储一些常用的信息, 这是一个经常会使用的场景.
struct TimeConstants {
    static let secondsInOneDay = 86_400
}

/// Represents the expiration strategy used in storage.
///
/// - never: The item never expires.
/// - seconds: The item expires after a time duration of given seconds from now.
/// - days: The item expires after a time duration of given days from now.
/// - date: The item expires after a given date.

// 在 Swfit 里面, 会大量使用, Enum 当盒子使用的示例.
// 这又是一个. 在各种 API 里面, 对外提供的是统一的接口, 然后在内部处理的时候, 使用 case 进行分辨, 是一个通用的行为.
public enum StorageExpiration {
    /// The item never expires.
    case never
    /// The item expires after a time duration of given seconds from now.
    case seconds(TimeInterval)
    /// The item expires after a time duration of given days from now.
    case days(Int)
    /// The item expires after a given date.
    case date(Date)
    
    /// Indicates the item is already expired. Use this to skip cache.
    case expired

    func estimatedExpirationSince(_ date: Date) -> Date {
        switch self {
        case .never:
            // 就算是 never, 也是会返回一个 Date 的.
            // 这样可以让代码更加的好书写.
            return .distantFuture
        case .seconds(let seconds):
            return date.addingTimeInterval(seconds)
        case .days(let days):
            let duration: TimeInterval = TimeInterval(TimeConstants.secondsInOneDay) * TimeInterval(days)
            return date.addingTimeInterval(duration)
        case .date(let ref):
            return ref
        case .expired:
            return .distantPast
        }
    }
    
    var estimatedExpirationSinceNow: Date {
        return estimatedExpirationSince(Date())
    }
    
    var isExpired: Bool {
        return timeInterval <= 0
    }

    var timeInterval: TimeInterval {
        switch self {
        case .never: return .infinity
        case .seconds(let seconds): return seconds
        case .days(let days): return TimeInterval(TimeConstants.secondsInOneDay) * TimeInterval(days)
        case .date(let ref): return ref.timeIntervalSinceNow
        case .expired: return -(.infinity)
        }
    }
}

/// Represents the expiration extending strategy used in storage to after access.
///
/// - none: The item expires after the original time, without extending after access.
/// - cacheTime: The item expiration extends by the original cache time after each access.
/// - expirationTime: The item expiration extends by the provided time after each access.

/// 表示在存储中用于访问后的过期扩展策略。
///
/// - none: 项目在原始时间后过期，访问后不会延长。
/// - cacheTime: 项目在每次访问后，其过期时间将延长原始缓存时间。
/// - expirationTime: 项目在每次访问后，其过期时间将延长提供的时间。
///
public enum ExpirationExtending {
    /// The item expires after the original time, without extending after access.
    case none
    /// The item expiration extends by the original cache time after each access.
    case cacheTime
    /// The item expiration extends by the provided time after each access.
    case expirationTime(_ expiration: StorageExpiration)
}

/// Represents types which cost in memory can be calculated.
// 存储的占有 cost 的值. 也将这个值, 当做了 protocol 来进行计算. 
public protocol CacheCostCalculable {
    var cacheCost: Int { get }
}

/// Represents types which can be converted to and from data.

// 在 Disk Storage 里面用到了, 当需要进行 Data 转换的时候, 使用这个协议.
// 这个协议是对 Data 的包装, 所以 Data 默认就是实现了这个协议.

public protocol DataTransformable {
    func toData() throws -> Data
    static func fromData(_ data: Data) throws -> Self
    static var empty: Self { get }
}
