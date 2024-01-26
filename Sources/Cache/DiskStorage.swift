
import Foundation

/// Represents a set of conception related to storage which stores a certain type of value in disk.
/// This is a namespace for the disk storage types. A `Backend` with a certain `Config` will be used to describe the
/// storage. See these composed types for more information.

// 使用 Enum 当做 NameSpace 的案例.
// DiskStorage 的各个部分, 是通过 NameSpace 下的各个实际类发挥的作用.
public enum DiskStorage {
    
    // 直接使用了 Data 进行存储, 然后使用 File 的 Attribute 进行过期时间的管理.
    
    /// Represents a storage back-end for the `DiskStorage`. The value is serialized to data
    /// and stored as file in the file system under a specified location.
    /// 将数据, 变为 Data, 然后存储到文件系统里面.
    
    /// You can config a `DiskStorage.Backend` in its initializer by passing a `DiskStorage.Config` value.
    /// or modifying the `config` property after it being created. `DiskStorage` will use file's attributes to keep
    /// track of a file for its expiration or size limitation.
    
    // 对于 manager 来说, 专门的进行一个 Config 类的设计, 是一个非常通用的模式.
    // 使用一个, 统一的地方进行各种的取值, 要比类内各种杂乱无章的属性提取要好的多.
    
    // 这里使用了泛型.
    // 但是这里的 T, 主要是为了固定类型, 而不是在里面存储一个抽象的工具.
    public class Backend<T: DataTransformable> {
        /// The config used for this disk storage.
        public var config: Config
        
        // The final storage URL on disk, with `name` and `cachePathBlock` considered.
        // 真正存储的地方.
        public let directoryURL: URL
        
        // 专门的一个队列, 用来做文件属性的修改. 之所以需要这个的一个队列, 是为了修改文件属性的这个操作, 不要卡主当前的线程.
        let metaChangingQueue: DispatchQueue
        
        // 这就是一个内存值, 用来取值的时候快速判断当前的位置有没有存图.
        // 在初始化的时候, 会将文档里面的所有数据搂一遍, 将里面的数据, 存储到 maybeCached 里面.
        var maybeCached : Set<String>?
        let maybeCachedCheckingQueue = DispatchQueue(label: "com.onevcat.Kingfisher.maybeCachedCheckingQueue")
        
        // `false` if the storage initialized with an error. This prevents unexpected forcibly crash when creating
        // storage in the default cache.
        // 默认值是 true, 初始化的时候, 如果失败了会变为 false.
        // 在 public 相关的接口里面, 会用这个值拦截逻辑.
        private var storageReady: Bool = true
        
        /// Creates a disk storage with the given `DiskStorage.Config`.
        ///
        /// - Parameter config: The config used for this disk storage.
        /// - Throws: An error if the folder for storage cannot be got or created.
        public convenience init(config: Config) throws {
            self.init(noThrowConfig: config, creatingDirectory: false)
            try prepareDirectory()
        }
        
        // If `creatingDirectory` is `false`, the directory preparation will be skipped.
        // We need to call `prepareDirectory` manually after this returns.
        init(noThrowConfig config: Config, creatingDirectory: Bool) {
            var config = config
            
            let creation = Creation(config)
            self.directoryURL = creation.directoryURL
            
            // Break any possible retain cycle set by outside.
            config.cachePathBlock = nil
            self.config = config
            
            metaChangingQueue = DispatchQueue(label: creation.cacheName)
            setupCacheChecking()
            
            if creatingDirectory {
                try? prepareDirectory()
            }
        }
        
        private func setupCacheChecking() {
            maybeCachedCheckingQueue.async {
                do {
                    self.maybeCached = Set()
                    try self.config.fileManager.contentsOfDirectory(atPath: self.directoryURL.path).forEach { fileName in
                        self.maybeCached?.insert(fileName)
                    }
                } catch {
                    // Just disable the functionality if we fail to initialize it properly. This will just revert to
                    // the behavior which is to check file existence on disk directly.
                    self.maybeCached = nil
                }
            }
        }
        
        // Creates the storage folder.
        private func prepareDirectory() throws {
            let fileManager = config.fileManager
            let path = directoryURL.path
            
            guard !fileManager.fileExists(atPath: path) else { return }
            
            do {
                try fileManager.createDirectory(
                    atPath: path,
                    withIntermediateDirectories: true,
                    attributes: nil)
            } catch {
                self.storageReady = false
                throw KingfisherError.cacheError(reason: .cannotCreateDirectory(path: path, error: error))
            }
        }
        
        /// Stores a value to the storage under the specified key and expiration policy.
        /// - Parameters:
        ///   - value: The value to be stored.
        ///   - key: The key to which the `value` will be stored. If there is already a value under the key,
        ///          the old value will be overwritten by `value`.
        ///   - expiration: The expiration policy used by this store action.
        ///   - writeOptions: Data writing options used the new files.
        /// - Throws: An error during converting the value to a data format or during writing it to disk.
        // 使用 Disk 存图的逻辑.
        public func store(
            value: T,
            forKey key: String,
            expiration: StorageExpiration? = nil,
            writeOptions: Data.WritingOptions = []) throws
        {
            guard storageReady else {
                throw KingfisherError.cacheError(reason: .diskStorageIsNotReady(cacheURL: directoryURL))
            }
            
            let expiration = expiration ?? config.expiration
            // The expiration indicates that already expired, no need to store.
            guard !expiration.isExpired else { return }
            
            let data: Data
            do {
                data = try value.toData()
            } catch {
                throw KingfisherError.cacheError(reason: .cannotConvertToData(object: value, error: error))
            }
            
            let fileURL = cacheFileURL(forKey: key)
            do {
                try data.write(to: fileURL, options: writeOptions)
            } catch {
                // 如果是文件没有, 那么尝试修复一下.
                if error.isFolderMissing {
                    // The whole cache folder is deleted. Try to recreate it and write file again.
                    do {
                        try prepareDirectory()
                        try data.write(to: fileURL, options: writeOptions)
                    } catch {
                        throw KingfisherError.cacheError(
                            reason: .cannotCreateCacheFile(fileURL: fileURL, key: key, data: data, error: error)
                        )
                    }
                } else {
                    throw KingfisherError.cacheError(
                        reason: .cannotCreateCacheFile(fileURL: fileURL, key: key, data: data, error: error)
                    )
                }
            }
            
            // 然后进行新存储的文件的相关属性修改.
            let now = Date()
            let attributes: [FileAttributeKey : Any] = [
                // The last access date.
                .creationDate: now.fileAttributeDate,
                // The estimated expiration date.
                .modificationDate: expiration.estimatedExpirationSinceNow.fileAttributeDate
            ]
            do {
                try config.fileManager.setAttributes(attributes, ofItemAtPath: fileURL.path)
            } catch {
                try? config.fileManager.removeItem(at: fileURL)
                throw KingfisherError.cacheError(
                    reason: .cannotSetCacheFileAttribute(
                        filePath: fileURL.path,
                        attributes: attributes,
                        error: error
                    )
                )
            }
            
            maybeCachedCheckingQueue.async {
                self.maybeCached?.insert(fileURL.lastPathComponent)
            }
        }
        
        /// Gets a value from the storage.
        /// - Parameters:
        ///   - key: The cache key of value.
        ///   - extendingExpiration: The expiration policy used by this getting action.
        /// - Throws: An error during converting the data to a value or during operation of disk files.
        /// - Returns: The value under `key` if it is valid and found in the storage. Otherwise, `nil`.
        
        // 在 DiskStorage 里面, 是将对于数据获取的能力, 包装成为了一个同步方法
        // 但是在调用的时候, 是使用了新的队列, 在队列中调用. 然后使用闭包进行的回调.
        public func value(forKey key: String, extendingExpiration: ExpirationExtending = .cacheTime) throws -> T? {
            return try value(forKey: key, referenceDate: Date(), actuallyLoad: true, extendingExpiration: extendingExpiration)
        }
        
        func value(
            forKey key: String,
            referenceDate: Date,
            actuallyLoad: Bool,
            extendingExpiration: ExpirationExtending) throws -> T?
        {
            guard storageReady else {
                throw KingfisherError.cacheError(reason: .diskStorageIsNotReady(cacheURL: directoryURL))
            }
            
            let fileManager = config.fileManager
            let fileURL = cacheFileURL(forKey: key)
            let filePath = fileURL.path
            
            let fileMaybeCached = maybeCachedCheckingQueue.sync {
                return maybeCached?.contains(fileURL.lastPathComponent) ?? true
            }
            guard fileMaybeCached else {
                return nil
            }
            guard fileManager.fileExists(atPath: filePath) else {
                return nil
            }
            
            let meta: FileMeta
            do {
                let resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey, .creationDateKey]
                meta = try FileMeta(fileURL: fileURL, resourceKeys: resourceKeys)
            } catch {
                throw KingfisherError.cacheError(
                    reason: .invalidURLResource(error: error, key: key, url: fileURL))
            }
            
            // 文件超时了.
            if meta.expired(referenceDate: referenceDate) {
                return nil
            }
            // 限制了, T 的类型必须是, 所以它调用 empty 是没有问题的.
            if !actuallyLoad { return T.empty }
            
            do {
                let data = try Data(contentsOf: fileURL)
                // 使用了 T.fromData 来做真正的从 data 到 Obj 的转换 .
                let obj = try T.fromData(data)
                // 对于文件的修改, 专门到一个队列里面, 这算是函数的副作用, 不影响主逻辑.
                metaChangingQueue.async {
                    meta.extendExpiration(with: fileManager, extendingExpiration: extendingExpiration)
                }
                return obj
            } catch {
                throw KingfisherError.cacheError(reason: .cannotLoadDataFromDisk(url: fileURL, error: error))
            }
        }
        
        /// Whether there is valid cached data under a given key.
        /// - Parameter key: The cache key of value.
        /// - Returns: If there is valid data under the key, `true`. Otherwise, `false`.
        ///
        /// - Note:
        /// This method does not actually load the data from disk, so it is faster than directly loading the cached value
        /// by checking the nullability of `value(forKey:extendingExpiration:)` method.
        ///
        public func isCached(forKey key: String) -> Bool {
            return isCached(forKey: key, referenceDate: Date())
        }
        
        /// Whether there is valid cached data under a given key and a reference date.
        /// - Parameters:
        ///   - key: The cache key of value.
        ///   - referenceDate: A reference date to check whether the cache is still valid.
        /// - Returns: If there is valid data under the key, `true`. Otherwise, `false`.
        ///
        /// - Note:
        /// If you pass `Date()` to `referenceDate`, this method is identical to `isCached(forKey:)`. Use the
        /// `referenceDate` to determine whether the cache is still valid for a future date.
        public func isCached(forKey key: String, referenceDate: Date) -> Bool {
            do {
                // 不触发真正的修改文件属性的操作. 只是为了查看缓存状态.
                let result = try value(
                    forKey: key,
                    referenceDate: referenceDate,
                    actuallyLoad: false,
                    extendingExpiration: .none
                )
                return result != nil
            } catch {
                return false
            }
        }
        
        /// Removes a value from a specified key.
        /// - Parameter key: The cache key of value.
        /// - Throws: An error during removing the value.
        public func remove(forKey key: String) throws {
            let fileURL = cacheFileURL(forKey: key)
            try removeFile(at: fileURL)
        }
        
        func removeFile(at url: URL) throws {
            try config.fileManager.removeItem(at: url)
        }
        
        /// Removes all values in this storage.
        /// - Throws: An error during removing the values.
        public func removeAll() throws {
            try removeAll(skipCreatingDirectory: false)
        }
        
        func removeAll(skipCreatingDirectory: Bool) throws {
            try config.fileManager.removeItem(at: directoryURL)
            if !skipCreatingDirectory {
                try prepareDirectory()
            }
        }
        
        /// The URL of the cached file with a given computed `key`.
        ///
        /// - Parameter key: The final computed key used when caching the image. Please note that usually this is not
        /// the `cacheKey` of an image `Source`. It is the computed key with processor identifier considered.
        ///
        /// - Note:
        /// This method does not guarantee there is an image already cached in the returned URL. It just gives your
        /// the URL that the image should be if it exists in disk storage, with the give key.
        ///
        public func cacheFileURL(forKey key: String) -> URL {
            let fileName = cacheFileName(forKey: key)
            return directoryURL.appendingPathComponent(fileName, isDirectory: false)
        }
        
        func cacheFileName(forKey key: String) -> String {
            if config.usesHashedFileName {
                let hashedKey = key.kf.md5
                if let ext = config.pathExtension {
                    return "\(hashedKey).\(ext)"
                } else if config.autoExtAfterHashedFileName,
                          let ext = key.kf.ext {
                    return "\(hashedKey).\(ext)"
                }
                return hashedKey
            } else {
                if let ext = config.pathExtension {
                    return "\(key).\(ext)"
                }
                return key
            }
        }
        
        func allFileURLs(for propertyKeys: [URLResourceKey]) throws -> [URL] {
            let fileManager = config.fileManager
            
            // 如果不传, 那么会获取到所有的默认属性.
            guard let directoryEnumerator = fileManager.enumerator(
                at: directoryURL, includingPropertiesForKeys: propertyKeys, options: .skipsHiddenFiles) else
            {
                throw KingfisherError.cacheError(reason: .fileEnumeratorCreationFailed(url: directoryURL))
            }
            
            guard let urls = directoryEnumerator.allObjects as? [URL] else {
                throw KingfisherError.cacheError(reason: .invalidFileEnumeratorContent(url: directoryURL))
            }
            return urls
        }
        
        /// Removes all expired values from this storage.
        /// - Throws: A file manager error during removing the file.
        /// - Returns: The URLs for removed files.
        public func removeExpiredValues() throws -> [URL] {
            return try removeExpiredValues(referenceDate: Date())
        }
        
        func removeExpiredValues(referenceDate: Date) throws -> [URL] {
            let propertyKeys: [URLResourceKey] = [
                .isDirectoryKey,
                .contentModificationDateKey
            ]
            
            let urls = try allFileURLs(for: propertyKeys)
            let keys = Set(propertyKeys)
            let expiredFiles = urls.filter { fileURL in
                do {
                    let meta = try FileMeta(fileURL: fileURL, resourceKeys: keys)
                    if meta.isDirectory {
                        return false
                    }
                    return meta.expired(referenceDate: referenceDate)
                } catch {
                    return true
                }
            }
            try expiredFiles.forEach { url in
                try removeFile(at: url)
            }
            return expiredFiles
        }
        
        /// Removes all size exceeded values from this storage.
        /// - Throws: A file manager error during removing the file.
        /// - Returns: The URLs for removed files.
        ///
        /// - Note: This method checks `config.sizeLimit` and remove cached files in an LRU (Least Recently Used) way.
        func removeSizeExceededValues() throws -> [URL] {
            
            if config.sizeLimit == 0 { return [] } // Back compatible. 0 means no limit.
            
            var size = try totalSize()
            if size < config.sizeLimit { return [] }
            
            let propertyKeys: [URLResourceKey] = [
                .isDirectoryKey,
                .creationDateKey,
                .fileSizeKey
            ]
            let keys = Set(propertyKeys)
            
            let urls = try allFileURLs(for: propertyKeys)
            var pendings: [FileMeta] = urls.compactMap { fileURL in
                guard let meta = try? FileMeta(fileURL: fileURL, resourceKeys: keys) else {
                    return nil
                }
                return meta
            }
            // Sort by last access date. Most recent file first.
            pendings.sort(by: FileMeta.lastAccessDate)
            
            var removed: [URL] = []
            let target = config.sizeLimit / 2
            while size > target, let meta = pendings.popLast() {
                size -= UInt(meta.fileSize)
                try removeFile(at: meta.url)
                removed.append(meta.url)
            }
            /*
             这段逻辑中的 let target = config.sizeLimit / 2 的设计可能是为了在达到限制时释放一部分空间，而不是立即释放整个超出限制的空间。这样可以在删除文件时更加谨慎，避免一次性删除太多文件导致性能问题或者影响应用的正常运行。

             通过将 target 设为 config.sizeLimit / 2，它表示一旦缓存的总大小超过限制的一半时就开始删除文件，直到缓存大小减少到限制的一半以下。这种策略可以在释放空间的同时保留一部分缓存，以提高性能和响应速度。
             
             所以, 这里在超过限制了之后, 不是只删一张, 而是删很多张.
             */
            return removed
        }
        
        /// Gets the total file size of the folder in bytes.
        public func totalSize() throws -> UInt {
            let propertyKeys: [URLResourceKey] = [.fileSizeKey]
            let urls = try allFileURLs(for: propertyKeys)
            let keys = Set(propertyKeys)
            let totalSize: UInt = urls.reduce(0) { size, fileURL in
                do {
                    let meta = try FileMeta(fileURL: fileURL, resourceKeys: keys)
                    return size + UInt(meta.fileSize)
                } catch {
                    return size
                }
            }
            return totalSize
        }
    }
}

extension DiskStorage {
    /// Represents the config used in a `DiskStorage`.
    public struct Config {
        
        /// The file size limit on disk of the storage in bytes. 0 means no limit.
        public var sizeLimit: UInt
        
        /// The `StorageExpiration` used in this disk storage. Default is `.days(7)`,
        /// means that the disk cache would expire in one week.
        public var expiration: StorageExpiration = .days(7)
        
        /// The preferred extension of cache item. It will be appended to the file name as its extension.
        /// Default is `nil`, means that the cache file does not contain a file extension.
        public var pathExtension: String? = nil
        
        /// Default is `true`, means that the cache file name will be hashed before storing.
        public var usesHashedFileName = true
        
        /// Default is `false`
        /// If set to `true`, image extension will be extracted from original file name and append to
        /// the hased file name and used as the cache key on disk.
        public var autoExtAfterHashedFileName = false
        
        /// Closure that takes in initial directory path and generates
        /// the final disk cache path. You can use it to fully customize your cache path.
        // 默认值为false。如果设置为true，则图像的文件扩展名将从原始文件名中提取，并附加到哈希文件名后，用作磁盘上的缓存键。
        public var cachePathBlock: ((_ directory: URL, _ cacheName: String) -> URL)! = {
            (directory, cacheName) in
            return directory.appendingPathComponent(cacheName, isDirectory: true)
        }
        
        let name: String
        let fileManager: FileManager
        let directory: URL?
        
        /// Creates a config value based on given parameters.
        ///
        /// - Parameters:
        ///   - name: The name of cache. It is used as a part of storage folder. It is used to identify the disk
        ///           storage. Two storages with the same `name` would share the same folder in disk, and it should
        ///           be prevented.
        ///   - sizeLimit: The size limit in bytes for all existing files in the disk storage.
        ///   - fileManager: The `FileManager` used to manipulate files on disk. Default is `FileManager.default`.
        ///   - directory: The URL where the disk storage should live. The storage will use this as the root folder,
        ///                and append a path which is constructed by input `name`. Default is `nil`, indicates that
        ///                the cache directory under user domain mask will be used.
        public init(
            name: String,
            sizeLimit: UInt,
            fileManager: FileManager = .default,
            directory: URL? = nil)
        {
            self.name = name
            self.fileManager = fileManager
            self.directory = directory
            self.sizeLimit = sizeLimit
        }
    }
}

extension DiskStorage {
    
    // 将, 对于 FileURL 和其中的元信息的提取的逻辑, 封装到了这个类当中 .
    struct FileMeta {
        
        let url: URL
        
        let lastAccessDate: Date?
        let estimatedExpirationDate: Date?
        let isDirectory: Bool
        let fileSize: Int
        
        static func lastAccessDate(lhs: FileMeta, rhs: FileMeta) -> Bool {
            return lhs.lastAccessDate ?? .distantPast > rhs.lastAccessDate ?? .distantPast
        }
        
        init(fileURL: URL, resourceKeys: Set<URLResourceKey>) throws {
            /*
             该方法首先检查URL实例是否已缓存指定的资源数值。如果是，则将缓存的资源数值返回给调用者。如果没有，则该方法同步从后端存储中获取资源数值，将其添加到URL对象的缓存中，并返回填充的URLResourceValues实例。
             返回的URLResourceValues实例仅包含与keys参数的内容相对应的成员。
             返回的资源数值的类型取决于由键指定的资源属性。有关详细信息，请参阅要访问的特定URLResourceKey的文档。
             如果在keys中没有给定键的可用值，则返回的URLResourceValues对应项为nil。
             如果该方法无法确定值的可用性或检索其值，则会抛出错误
             */
            let meta = try fileURL.resourceValues(forKeys: resourceKeys)
            // 所有的, 关于文件的基本信息, 是通过文件系统记录的值获取到的.
            // 有可能获取不到的值, 都是 optinal 的.
            self.init(
                fileURL: fileURL,
                lastAccessDate: meta.creationDate, // 创建时间, 是被当做上次访问时间使用了
                estimatedExpirationDate: meta.contentModificationDate, // 修改时间, 是被当做过期时间使用了
                isDirectory: meta.isDirectory ?? false,
                fileSize: meta.fileSize ?? 0)
        }
        
        init(
            fileURL: URL,
            lastAccessDate: Date?,
            estimatedExpirationDate: Date?,
            isDirectory: Bool,
            fileSize: Int)
        {
            self.url = fileURL
            self.lastAccessDate = lastAccessDate
            self.estimatedExpirationDate = estimatedExpirationDate
            self.isDirectory = isDirectory
            self.fileSize = fileSize
        }
        
        func expired(referenceDate: Date) -> Bool {
            return estimatedExpirationDate?.isPast(referenceDate: referenceDate) ?? true
        }
        
        // 从这里来看, 作者是将 modificationDate 这个值, 当做了过期时间来进行使用的了.
        func extendExpiration(with fileManager: FileManager, extendingExpiration: ExpirationExtending) {
            guard let lastAccessDate = lastAccessDate,
                  let lastEstimatedExpiration = estimatedExpirationDate else
            {
                return
            }
            
            let attributes: [FileAttributeKey : Any]
            
            switch extendingExpiration {
            case .none:
                // not extending expiration time here
                return
            case .cacheTime:
                // 用原来的差值, 进行更新.
                let originalExpiration: StorageExpiration =
                    .seconds(lastEstimatedExpiration.timeIntervalSince(lastAccessDate))
                attributes = [
                    .creationDate: Date().fileAttributeDate,
                    .modificationDate: originalExpiration.estimatedExpirationSinceNow.fileAttributeDate
                ]
            case .expirationTime(let expirationTime):
                attributes = [
                    .creationDate: Date().fileAttributeDate,
                    .modificationDate: expirationTime.estimatedExpirationSinceNow.fileAttributeDate
                ]
            }
            
            // 使用 fileManager.setAttributes 进行状态的更新.
            try? fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        }
    }
}

extension DiskStorage {
    // 这里封装了一下, 存储路径的创建逻辑.
    struct Creation {
        let directoryURL: URL
        let cacheName: String
        
        init(_ config: Config) {
            let url: URL
            // 增加了对于不配置存储位置的处理逻辑.
            if let directory = config.directory {
                url = directory
            } else {
                url = config.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            }
            
            cacheName = "com.onevcat.Kingfisher.ImageCache.\(config.name)"
            directoryURL = config.cachePathBlock(url, cacheName)
        }
    }
}

fileprivate extension Error {
    // 对于 Error 来说, 有些特殊的判断. 直接使用特定的 domian + code 来进行.
    // 每次都将这个逻辑进行
    var isFolderMissing: Bool {
        let nsError = self as NSError
        guard nsError.domain == NSCocoaErrorDomain, nsError.code == 4 else {
            return false
        }
        guard let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError else {
            return false
        }
        guard underlyingError.domain == NSPOSIXErrorDomain, underlyingError.code == 2 else {
            return false
        }
        return true
    }
}
