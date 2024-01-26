
import Foundation

/*
 所有的, 有关于内存存储的信息, 都会在 MemoryStorage 这个类里面.
 */
/// Represents a set of conception related to storage which stores a certain type of value in memory.
/// This is a namespace for the memory storage types. A `Backend` with a certain `Config` will be used to describe the
/// storage. See these composed types for more information.

/// 表示与存储相关的一组概念，用于在内存中存储某种类型的值。
/// 这是内存存储类型的命名空间。带有特定 `Config` 的 `Backend` 用于描述存储。有关更多信息，请参阅这些组合类型。

public enum MemoryStorage {

    /// Represents a storage which stores a certain type of value in memory. It provides fast access,
    /// but limited storing size. The stored value type needs to conform to `CacheCostCalculable`,
    /// and its `cacheCost` will be used to determine the cost of size for the cache item.
    ///
    /// You can config a `MemoryStorage.Backend` in its initializer by passing a `MemoryStorage.Config` value.
    /// or modifying the `config` property after it being created. The backend of `MemoryStorage` has
    /// upper limitation on cost size in memory and item count. All items in the storage has an expiration
    /// date. When retrieved, if the target item is already expired, it will be recognized as it does not
    /// exist in the storage. The `MemoryStorage` also contains a scheduled self clean task, to evict expired
    /// items from memory.
    
    /// 表示一种在内存中存储特定类型值的存储。它提供快速访问，但存储大小有限。存储的值类型需要符合 `CacheCostCalculable`，
    /// 其 `cacheCost` 将用于确定缓存项的大小成本。
    ///
    /// 您可以通过在其初始化器中传递 `MemoryStorage.Config` 值或在创建后修改 `config` 属性来配置 `MemoryStorage.Backend`。
    /// `MemoryStorage` 的后端在内存中具有成本大小和项目计数的上限。存储中的所有项目都有一个过期日期。在检索时，如果目标项目已经过期，
    /// 它将被视为在存储中不存在。`MemoryStorage` 还包含一个预定的自清理任务，用于从内存中清除已过期的项目。

    // 真正的内存存储, 是使用了这个类来完成的.
    // 在通用的第三方类库里面, 是大量的使用了泛型.
    
    public class Backend<T: CacheCostCalculable> {
        // 直接使用了 NSCache 来做处理.
        // NSCache 这个类要求了, 存储的 Obj 必须是一个引用数据类型. NSCache 的内部, 本身其实是一个线程安全的对象. 但是在本类里面, 还是增加了锁.
        // 这里之所以, 使用 NSString, 是因为这个类型才实现了 NSCoping 协议的.
        let storage = NSCache<NSString, StorageObject<T>>()

        // Keys trackes the objects once inside the storage. For object removing triggered by user, the corresponding
        // key would be also removed. However, for the object removing triggered by cache rule/policy of system, the
        // key will be remained there until next `removeExpired` happens.
        //
        // Breaking the strict tracking could save additional locking behaviors.
        // See https://github.com/onevcat/Kingfisher/issues/1233
        
        // Keys 跟踪一旦进入存储中的对象。对于由用户触发的对象删除，相应的键也将被删除。但是，对于由系统的缓存规则/策略触发的对象删除，
        // 键将保留在那里，直到下一次 `removeExpired` 发生。
        //
        // 打破严格的跟踪可以节省额外的锁定行为。
        // 参见 https://github.com/onevcat/Kingfisher/issues/1233
        var keys = Set<String>()

        private var cleanTimer: Timer? = nil // 这个值只会在初始化的时候, 使用一次.
        private let lock = NSLock()

        /// The config used in this storage. It is a value you can set and
        /// use to config the storage in air.
        public var config: Config {
            didSet {
                // config 的修改, 可以直接修改 storage 里面的数据.
                storage.totalCostLimit = config.totalCostLimit
                storage.countLimit = config.countLimit
            }
        }

        /// Creates a `MemoryStorage` with a given `config`.
        ///
        /// - Parameter config: The config used to create the storage. It determines the max size limitation,
        ///                     default expiration setting and more.
        public init(config: Config) {
            self.config = config
            storage.totalCostLimit = config.totalCostLimit
            storage.countLimit = config.countLimit

            cleanTimer = .scheduledTimer(withTimeInterval: config.cleanInterval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.removeExpired()
            }
        }
        
        // 可以看到, 对于 MomoryStorage 来说, 所有的 api 都是同步的函数. 

        /// Removes the expired values from the storage.
        // 内存里面的这个 Cache, 会定期的进行删除.
        public func removeExpired() {
            lock.lock()
            defer { lock.unlock() }
            for key in keys {
                // 可以看到, 是直接使用了 NSString 这个对象.
                let nsKey = key as NSString
                guard let object = storage.object(forKey: nsKey) else {
                    // This could happen if the object is moved by cache `totalCostLimit` or `countLimit` rule.
                    // We didn't remove the key yet until now, since we do not want to introduce additional lock.
                    // See https://github.com/onevcat/Kingfisher/issues/1233
                    keys.remove(key)
                    continue
                }
                // 一个对象, 是否处于过期的状态, 是直接由存储的 Item 决定的.
                if object.isExpired {
                    storage.removeObject(forKey: nsKey)
                    keys.remove(key)
                }
            }
        }

        /// Stores a value to the storage under the specified key and expiration policy.
        /// - Parameters:
        ///   - value: The value to be stored.
        ///   - key: The key to which the `value` will be stored.
        ///   - expiration: The expiration policy used by this store action.
        /// - Throws: No error will
        public func store(
            value: T,
            forKey key: String,
            expiration: StorageExpiration? = nil)
        {
            storeNoThrow(value: value, forKey: key, expiration: expiration)
        }

        // The no throw version for storing value in cache. Kingfisher knows the detail so it
        // could use this version to make syntax simpler internally.
        func storeNoThrow(
            value: T,
            forKey key: String,
            expiration: StorageExpiration? = nil)
        {
            lock.lock()
            defer { lock.unlock() }
            
            // 这种, 每次进行操作的时候, 进行配置是一个很好的方式.
            // 如果由参数, 就使用传递的, 否则就使用默认的.
            let expiration = expiration ?? config.expiration
            // The expiration indicates that already expired, no need to store.
            guard !expiration.isExpired else { return }
            
            let object: StorageObject<T>
            if config.keepWhenEnteringBackground {
                object = BackgroundKeepingStorageObject(value, expiration: expiration)
            } else {
                object = StorageObject(value, expiration: expiration)
            }
            storage.setObject(object, forKey: key as NSString, cost: value.cacheCost)
            keys.insert(key)
        }
        
        /// Gets a value from the storage.
        ///
        /// - Parameters:
        ///   - key: The cache key of value.
        ///   - extendingExpiration: The expiration policy used by this getting action.
        /// - Returns: The value under `key` if it is valid and found in the storage. Otherwise, `nil`.
        // 这个方法, 在目前项目里面, 还不是 public 的. 目前变为了 Public 了.
        // 从设计上来说, 如果不进行 Public, 那么第二个参数根本就是没有意义的.
        public func value(forKey key: String, extendingExpiration: ExpirationExtending = .cacheTime) -> T? {
            guard let object = storage.object(forKey: key as NSString) else {
                return nil
            }
            // 如果已经过期了, 那么 get 函数里面, 是不会返回任何的数据的
            if object.isExpired {
                return nil
            }
            // 在 get 操作里面, 直接就进行有效期的延长.
            object.extendExpiration(extendingExpiration)
            return object.value
        }

        /// Whether there is valid cached data under a given key.
        /// - Parameter key: The cache key of value.
        /// - Returns: If there is valid data under the key, `true`. Otherwise, `false`.
        public func isCached(forKey key: String) -> Bool {
            // 复用 value 的逻辑, 但是不进行有效期的延长触发.
            guard let _ = value(forKey: key, extendingExpiration: .none) else {
                return false
            }
            return true
        }

        /// Removes a value from a specified key.
        /// - Parameter key: The cache key of value.
        public func remove(forKey key: String) {
            lock.lock()
            defer { lock.unlock() }
            storage.removeObject(forKey: key as NSString)
            keys.remove(key)
        }

        /// Removes all values in this storage.
        public func removeAll() {
            lock.lock()
            defer { lock.unlock() }
            storage.removeAllObjects()
            keys.removeAll()
        }
    }
}

extension MemoryStorage {
    /// Represents the config used in a `MemoryStorage`.
    public struct Config {

        /// Total cost limit of the storage in bytes.
        public var totalCostLimit: Int

        /// The item count limit of the memory storage.
        public var countLimit: Int = .max

        /// The `StorageExpiration` used in this memory storage. Default is `.seconds(300)`,
        /// means that the memory cache would expire in 5 minutes.
        public var expiration: StorageExpiration = .seconds(300)

        /// The time interval between the storage do clean work for swiping expired items.
        public var cleanInterval: TimeInterval
        
        /// Whether the newly added items to memory cache should be purged when the app goes to background.
        ///
        /// By default, the cached items in memory will be purged as soon as the app goes to background to ensure
        /// least memory footprint. Enabling this would prevent this behavior and keep the items alive in cache even
        /// when your app is not in foreground anymore.
        ///
        /// Default is `false`. After setting `true`, only the newly added cache objects are affected. Existing
        /// objects which are already in the cache while this value was `false` will be still be purged when entering
        /// background.
        
        /// 是否在应用程序进入后台时清除新添加到内存缓存中的项目。
        ///
        /// 默认情况下，一旦应用程序进入后台，内存中的缓存项目将被清除，以确保最小的内存占用。启用此选项将阻止此行为，
        /// 即使您的应用程序不再在前台运行，也会保持项目在缓存中保持活动状态。
        ///
        /// 默认值为 `false`。在设置为 `true` 后，只有新添加的缓存对象受到影响。而在此值为 `false` 时已存在在缓存中的对象，
        /// 在进入后台时仍将被清除。

        public var keepWhenEnteringBackground: Bool = false

        /// Creates a config from a given `totalCostLimit` value.
        ///
        /// - Parameters:
        ///   - totalCostLimit: Total cost limit of the storage in bytes.
        ///   - cleanInterval: The time interval between the storage do clean work for swiping expired items.
        ///                    Default is 120, means the auto eviction happens once per two minutes.
        ///
        /// - Note:
        /// Other members of `MemoryStorage.Config` will use their default values when created.
        public init(totalCostLimit: Int, cleanInterval: TimeInterval = 120) {
            self.totalCostLimit = totalCostLimit
            self.cleanInterval = cleanInterval
        }
    }
}

extension MemoryStorage {
    
    /*
     具体来说，实现了NSDiscardableContent协议的对象表示它们可能在任何时间被标记为"可丢弃"，并在系统需要释放内存时，可能会被自动释放。这通常用于缓存等场景，允许在内存不足时释放部分缓存以腾出空间。

     在实现这个协议的类中，有两个主要方法需要实现：

     beginContentAccess: 用于标记对象即将被访问。
     endContentAccess: 用于标记对象的访问结束。
     如果对象在beginContentAccess和endContentAccess之间没有被标记为"可丢弃"，系统就会认为它是重要的，不会在内存不足时释放。

     NSDiscardableContent在iOS和macOS平台上都有，但需要注意的是，随着系统和Objective-C的演进，新的内存管理技术和Swift语言的引入，现代应用程序在很多情况下可能使用更先进的内存管理方式，而不仅仅依赖于NSDiscardableContent
     */
    // 没太明白, KF 如何组织内存被释放的, 不过这个不重要. 
    class BackgroundKeepingStorageObject<T>: StorageObject<T>, NSDiscardableContent {
        var accessing = true
        
        func beginContentAccess() -> Bool {
            if value != nil {
                accessing = true
            } else {
                accessing = false
            }
            return accessing
        }
        
        func endContentAccess() {
            accessing = false
        }
        
        func discardContentIfPossible() {
            value = nil
        }
        
        func isContentDiscarded() -> Bool {
            return value == nil
        }
    }
    
    // 在内存里面, 真正的存储的起始是这个对象.
    // 除了原本的 value 之外, 就是有关超时的概念的管理了.
    class StorageObject<T> {
        var value: T?
        let expiration: StorageExpiration
        
        private(set) var estimatedExpiration: Date
        
        // 使用参数, 对于属性进行赋值.
        // 以及使用属性对于后续的属性进行赋值, 进行了划分.
        init(_ value: T, expiration: StorageExpiration) {
            self.value = value
            self.expiration = expiration
            
            self.estimatedExpiration = expiration.estimatedExpirationSinceNow
        }

        // 每次的 Get 操作, 都会使用该函数, 算作是 Get 的副作用了.
        func extendExpiration(_ extendingExpiration: ExpirationExtending = .cacheTime) {
            switch extendingExpiration {
            case .none:
                return
            case .cacheTime:
                self.estimatedExpiration = expiration.estimatedExpirationSinceNow
            case .expirationTime(let expirationTime):
                self.estimatedExpiration = expirationTime.estimatedExpirationSinceNow
            }
        }
        
        var isExpired: Bool {
            return estimatedExpiration.isPast
        }
    }
}
