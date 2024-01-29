

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The downloading progress block type.
/// The parameter value is the `receivedSize` of current response.
/// The second parameter is the total expected data length from response's "Content-Length" header.
/// If the expected length is not available, this block will not be called.

/// 下载进度块类型。
/// 第一个参数的值是当前响应的 receivedSize。
/// 第二个参数是来自响应的 "Content-Length" 头部的总期望数据长度。
/// 如果期望的长度不可用，此块将不会被调用。
public typealias DownloadProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)

/// Represents the result of a Kingfisher retrieving image task.
// 这个在原来的版本里面, 应该是几个参数聚合在一起. 
public struct RetrieveImageResult {
    /// Gets the image object of this result.
    public let image: KFCrossPlatformImage
    
    /// Gets the cache source of the image. It indicates from which layer of cache this image is retrieved.
    /// If the image is just downloaded from network, `.none` will be returned.
    public let cacheType: CacheType
    
    /// The `Source` which this result is related to. This indicated where the `image` of `self` is referring.
    public let source: Source
    
    /// The original `Source` from which the retrieve task begins. It can be different from the `source` property.
    /// When an alternative source loading happened, the `source` will be the replacing loading target, while the
    /// `originalSource` will be kept as the initial `source` which issued the image loading process.
    public let originalSource: Source
    
    /// Gets the data behind the result.
    ///
    /// If this result is from a network downloading (when `cacheType == .none`), calling this returns the downloaded
    /// data. If the reuslt is from cache, it serializes the image with the given cache serializer in the loading option
    /// and returns the result.
    ///
    /// - Note:
    /// This can be a time-consuming action, so if you need to use the data for multiple times, it is suggested to hold
    /// it and prevent keeping calling this too frequently.
    public let data: () -> Data?
}

/// A struct that stores some related information of an `KingfisherError`. It provides some context information for
/// a pure error so you can identify the error easier.
public struct PropagationError {
    
    /// The `Source` to which current `error` is bound.
    public let source: Source
    
    /// The actual error happens in framework.
    public let error: KingfisherError
}


/// The downloading task updated block type. The parameter `newTask` is the updated new task of image setting process.
/// It is a `nil` if the image loading does not require an image downloading process. If an image downloading is issued,
/// this value will contain the actual `DownloadTask` for you to keep and cancel it later if you need.
public typealias DownloadTaskUpdatedBlock = ((_ newTask: DownloadTask?) -> Void)

/// Main manager class of Kingfisher. It connects Kingfisher downloader and cache,
/// to provide a set of convenience methods to use Kingfisher for tasks.
/// You can use this class to retrieve an image via a specified URL from web or cache.
// 这个类库的入口对象.
// Downloader, Cacher, 以及各种的 Options.
// 实际上, KF 是按照任务进行的数据的组织, 下载任务和缓存任务是由 downloader 和 cacheer 执行的. 其他的各种任务, 是 defaultOption 和 传入的 Option 组合使用的
public class KingfisherManager {
    
    /// Represents a shared manager used across Kingfisher.
    /// Use this instance for getting or storing images with Kingfisher.
    public static let shared = KingfisherManager()
    
    /// The `ImageCache` used by this manager. It is `ImageCache.default` by default.
    /// If a cache is specified in `KingfisherManager.defaultOptions`, the value in `defaultOptions` will be
    /// used instead.
    public var cache: ImageCache
    
    /// The `ImageDownloader` used by this manager. It is `ImageDownloader.default` by default.
    /// If a downloader is specified in `KingfisherManager.defaultOptions`, the value in `defaultOptions` will be
    /// used instead.
    public var downloader: ImageDownloader
    
    /// Default options used by the manager. This option will be used in
    /// Kingfisher manager related methods, as well as all view extension methods.
    /// You can also passing other options for each image task by sending an `options` parameter
    /// to Kingfisher's APIs. The per image options will overwrite the default ones,
    /// if the option exists in both.
    /// 管理器使用的默认选项。这些选项将在 Kingfisher 管理器相关的方法以及所有视图扩展方法中使用。
    /// 您还可以通过向 Kingfisher 的 API 发送一个 `options` 参数为每个图像任务传递其他选项。
    /// 如果在默认选项和每个图像任务选项中都存在某个选项，则每个图像任务中的选项将覆盖默认选项。
    // 所有的 API, 传递过来的 options 的数据, 最终都是要和 defaultOptions 进行一次合并的操作.
    // 这个 defaultOptions 是一个可以重新赋值的, 也就是说 App 可以将这个值进行更改, 来整体的调整一下, 整个 App 使用 KF 的时候的行为.
    public var defaultOptions = KingfisherOptionsInfo.empty
    
    // Use `defaultOptions` to overwrite the `downloader` and `cache`.
    // downloader, cache 是特殊的两个数据. 不应该被 defaultOptions 所影响.
    private var currentDefaultOptions: KingfisherOptionsInfo {
        return [.downloader(downloader), .targetCache(cache)] + defaultOptions
    }
    
    private let processingQueue: CallbackQueue
    
    // 这是 Private 的, 只能是 static default 才能使用.
    // 如果想要添加其他的任何 manager, 都需要填入对应的配置参数.
    private convenience init() {
        self.init(downloader: .default, cache: .default)
    }
    
    /// Creates an image setting manager with specified downloader and cache.
    ///
    /// - Parameters:
    ///   - downloader: The image downloader used to download images.
    ///   - cache: The image cache which stores memory and disk images.
    public init(downloader: ImageDownloader, cache: ImageCache) {
        self.downloader = downloader
        self.cache = cache
        
        let processQueueName = "com.onevcat.Kingfisher.KingfisherManager.processQueue.\(UUID().uuidString)"
        processingQueue = .dispatch(DispatchQueue(label: processQueueName))
    }
    
    // MARK: - Getting Images
    
    /// Gets an image from a given resource.
    /// - Parameters:
    ///   - resource: The `Resource` object defines data information like key or URL.
    ///   - options: Options to use when creating the image. 每个任务, 进行自定义操作的配置类.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called. `progressBlock` is always called in
    ///                    main queue. // 对于 UI 相关的操作, 进行对应的线程确认, 是一个很好的设计思路.
    ///   - downloadTaskUpdated: Called when a new image downloading task is created for current image retrieving. This
    ///                          usually happens when an alternative source is used to replace the original (failed)
    ///                          task. You can update your reference of `DownloadTask` if you want to manually `cancel`
    ///                          the new task.
    ///   - completionHandler: Called when the image retrieved and set finished. This completion handler will be invoked
    ///                        from the `options.callbackQueue`. If not specified, the main queue will be used.
    /// - Returns: A task represents the image downloading. If there is a download task starts for `.network` resource,
    ///            the started `DownloadTask` is returned. Otherwise, `nil` is returned.
    ///
    /// - Note:
    ///    This method will first check whether the requested `resource` is already in cache or not. If cached,
    ///    it returns `nil` and invoke the `completionHandler` after the cached image retrieved. Otherwise, it
    ///    will download the `resource`, store it in cache, then call `completionHandler`.
    
    // KF 的设计思路, 和 SDWebImage 没有太大的区别.
    // 这是根本的方法, 各个 View 的 extension, 都是使用这个方法来进行自定义的操作.
    @discardableResult
    public func retrieveImage(
        with resource: Resource,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        // resource.convertToSource()
        // 这里的设计思路, 和之前 OC 没有太多的区别.
        // 提供了大量的方法, 给外界最简单的用法. 然后, 自己在框架的内部, 进行相关的资源转化.
        return retrieveImage(
            with: resource.convertToSource(),
            options: options,
            progressBlock: progressBlock,
            downloadTaskUpdated: downloadTaskUpdated,
            completionHandler: completionHandler
        )
    }
    
    /// Gets an image from a given resource.
    ///
    /// - Parameters:
    ///   - source: The `Source` object defines data information from network or a data provider.
    ///   - options: Options to use when creating the image.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called. `progressBlock` is always called in
    ///                    main queue.
    ///   - downloadTaskUpdated: Called when a new image downloading task is created for current image retrieving. This
    ///                          usually happens when an alternative source is used to replace the original (failed)
    ///                          task. You can update your reference of `DownloadTask` if you want to manually `cancel`
    ///                          the new task.
    ///   - completionHandler: Called when the image retrieved and set finished. This completion handler will be invoked
    ///                        from the `options.callbackQueue`. If not specified, the main queue will be used.
    /// - Returns: A task represents the image downloading. If there is a download task starts for `.network` resource,
    ///            the started `DownloadTask` is returned. Otherwise, `nil` is returned.
    ///
    /// - Note:
    ///    This method will first check whether the requested `source` is already in cache or not. If cached,
    ///    it returns `nil` and invoke the `completionHandler` after the cached image retrieved. Otherwise, it
    ///    will try to load the `source`, store it in cache, then call `completionHandler`.
    ///
    @discardableResult
    public func retrieveImage(
        with source: Source,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        // 作为控制类, 提供了 currentDefaultOptions 进行相关的配置管理.
        // 真正的控制配置, 是 KingfisherParsedOptionsInfo
        let options = currentDefaultOptions + (options ?? .empty)
        let info = KingfisherParsedOptionsInfo(options)
        return retrieveImage(
            with: source,
            options: info,
            progressBlock: progressBlock,
            downloadTaskUpdated: downloadTaskUpdated,
            completionHandler: completionHandler)
    }
    
    func retrieveImage(
        with source: Source,
        options: KingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        var info = options
        if let block = progressBlock {
            info.onDataReceived = (info.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }
        return retrieveImage(
            with: source,
            options: info,
            downloadTaskUpdated: downloadTaskUpdated,
            progressiveImageSetter: nil,
            completionHandler: completionHandler)
    }
    
    
    // 最最重要的核心逻辑.
    func retrieveImage(
        with source: Source,
        options: KingfisherParsedOptionsInfo,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        progressiveImageSetter: ((KFCrossPlatformImage?) -> Void)? = nil,
        referenceTaskIdentifierChecker: (() -> Bool)? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        var options = options
        if let provider = ImageProgressiveProvider(options, refresh: { image in
            guard let setter = progressiveImageSetter else {
                return
            }
            guard let strategy = options.progressiveJPEG?.onImageUpdated(image) else {
                setter(image)
                return
            }
            switch strategy {
            case .default: setter(image)
            case .keepCurrent: break
            case .replace(let newImage): setter(newImage)
            }
        }) {
            options.onDataReceived = (options.onDataReceived ?? []) + [provider]
        }
        if let checker = referenceTaskIdentifierChecker {
            options.onDataReceived?.forEach {
                $0.onShouldApply = checker
            }
        }
        
        let retrievingContext = RetrievingContext(options: options, originalSource: source)
        var retryContext: RetryContext?
        
        // 在一个方法内部, 进行方法的定义, 然后稍后进行调用, 看来是更好的代码的组织方式.
        // 虽然这个方法内部可能比较大, 但是经过逻辑的分发, 其实每个逻辑块, 都能保持相关适量的大小.
        func startNewRetrieveTask(
            with source: Source,
            downloadTaskUpdated: DownloadTaskUpdatedBlock?
        ) {
            let newTask = self.retrieveImage(with: source, context: retrievingContext) { result in
                handler(currentSource: source, result: result)
            }
            downloadTaskUpdated?(newTask)
        }
        
        func failCurrentSource(_ source: Source, with error: KingfisherError) {
            // Skip alternative sources if the user cancelled it.
            guard !error.isTaskCancelled else {
                completionHandler?(.failure(error))
                return
            }
            // When low data mode constrained error, retry with the low data mode source instead of use alternative on fly.
            guard !error.isLowDataModeConstrained else {
                if let source = retrievingContext.options.lowDataModeSource {
                    retrievingContext.options.lowDataModeSource = nil
                    startNewRetrieveTask(with: source, downloadTaskUpdated: downloadTaskUpdated)
                } else {
                    // This should not happen.
                    completionHandler?(.failure(error))
                }
                return
            }
            if let nextSource = retrievingContext.popAlternativeSource() {
                retrievingContext.appendError(error, to: source)
                startNewRetrieveTask(with: nextSource, downloadTaskUpdated: downloadTaskUpdated)
            } else {
                // No other alternative source. Finish with error.
                if retrievingContext.propagationErrors.isEmpty {
                    completionHandler?(.failure(error))
                } else {
                    retrievingContext.appendError(error, to: source)
                    let finalError = KingfisherError.imageSettingError(
                        reason: .alternativeSourcesExhausted(retrievingContext.propagationErrors)
                    )
                    completionHandler?(.failure(finalError))
                }
            }
        }
        
        func handler(currentSource: Source, result: (Result<RetrieveImageResult, KingfisherError>)) -> Void {
            switch result {
            case .success:
                completionHandler?(result)
            case .failure(let error):
                if let retryStrategy = options.retryStrategy {
                    let context = retryContext?.increaseRetryCount() ?? RetryContext(source: source, error: error)
                    retryContext = context
                    
                    retryStrategy.retry(context: context) { decision in
                        switch decision {
                        case .retry(let userInfo):
                            retryContext?.userInfo = userInfo
                            startNewRetrieveTask(with: source, downloadTaskUpdated: downloadTaskUpdated)
                        case .stop:
                            failCurrentSource(currentSource, with: error)
                        }
                    }
                } else {
                    failCurrentSource(currentSource, with: error)
                }
            }
        }
        
        return retrieveImage(
            with: source,
            context: retrievingContext)
        {
            result in
            handler(currentSource: source, result: result)
        }
        
    }
    
    /*
     要么是 retrieveImageFromCache
     要么是 loadAndCacheImage
     所有的, 都是传递回调和 context.
     将盒子进行传递. 
     */
    private func retrieveImage(
        with source: Source,
        context: RetrievingContext,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        let options = context.options
        if options.forceRefresh {
            return loadAndCacheImage(
                source: source,
                context: context,
                completionHandler: completionHandler)?.value
            
        } else {
            // retrieveImageFromCache 里面, 其实是包含了对于 Disk 的检测的. 虽然从 disk 里面获取数据, 可能会耗时, 需要使用回调.
            let loadedFromCache = retrieveImageFromCache(
                source: source,
                context: context,
                completionHandler: completionHandler)
            
            if loadedFromCache {
                return nil
            }
            
            if options.onlyFromCache {
                let error = KingfisherError.cacheError(reason: .imageNotExisting(key: source.cacheKey))
                completionHandler?(.failure(error))
                return nil
            }
            
            return loadAndCacheImage(
                source: source,
                context: context,
                completionHandler: completionHandler)?.value
        }
    }
    
    func provideImage(
        provider: ImageDataProvider,
        options: KingfisherParsedOptionsInfo,
        completionHandler: ((Result<ImageLoadingResult, KingfisherError>) -> Void)?)
    {
        guard let  completionHandler = completionHandler else { return }
        provider.data { result in
            switch result {
            case .success(let data):
                (options.processingQueue ?? self.processingQueue).execute {
                    let processor = options.processor
                    let processingItem = ImageProcessItem.data(data)
                    guard let image = processor.process(item: processingItem, options: options) else {
                        options.callbackQueue.execute {
                            let error = KingfisherError.processorError(
                                reason: .processingFailed(processor: processor, item: processingItem))
                            completionHandler(.failure(error))
                        }
                        return
                    }
                    
                    options.callbackQueue.execute {
                        let result = ImageLoadingResult(image: image, url: nil, originalData: data)
                        completionHandler(.success(result))
                    }
                }
            case .failure(let error):
                options.callbackQueue.execute {
                    let error = KingfisherError.imageSettingError(
                        reason: .dataProviderError(provider: provider, error: error))
                    completionHandler(.failure(error))
                }
                
            }
        }
    }
    
    private func cacheImage(
        source: Source,
        options: KingfisherParsedOptionsInfo,
        context: RetrievingContext,
        result: Result<ImageLoadingResult, KingfisherError>,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?
    )
    {
        switch result {
        case .success(let value):
            let needToCacheOriginalImage = options.cacheOriginalImage &&
            options.processor != DefaultImageProcessor.default
            let coordinator = CacheCallbackCoordinator(
                shouldWaitForCache: options.waitForCache, shouldCacheOriginal: needToCacheOriginalImage)
            let result = RetrieveImageResult(
                image: options.imageModifier?.modify(value.image) ?? value.image,
                cacheType: .none,
                source: source,
                originalSource: context.originalSource,
                data: {  value.originalData }
            )
            // Add image to cache.
            let targetCache = options.targetCache ?? self.cache
            targetCache.store(
                value.image,
                original: value.originalData,
                forKey: source.cacheKey,
                options: options,
                toDisk: !options.cacheMemoryOnly)
            {
                _ in
                coordinator.apply(.cachingImage) {
                    completionHandler?(.success(result))
                }
            }
            
            // Add original image to cache if necessary.
            
            if needToCacheOriginalImage {
                let originalCache = options.originalCache ?? targetCache
                originalCache.storeToDisk(
                    value.originalData,
                    forKey: source.cacheKey,
                    processorIdentifier: DefaultImageProcessor.default.identifier,
                    expiration: options.diskCacheExpiration)
                {
                    _ in
                    coordinator.apply(.cachingOriginalImage) {
                        completionHandler?(.success(result))
                    }
                }
            }
            
            coordinator.apply(.cacheInitiated) {
                completionHandler?(.success(result))
            }
            
        case .failure(let error):
            completionHandler?(.failure(error))
        }
    }
    
    @discardableResult
    func loadAndCacheImage(
        source: Source,
        context: RetrievingContext,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask.WrappedTask?
    {
        let options = context.options
        func _cacheImage(_ result: Result<ImageLoadingResult, KingfisherError>) {
            cacheImage(
                source: source,
                options: options,
                context: context,
                result: result,
                completionHandler: completionHandler
            )
        }
        
        switch source {
        case .network(let resource):
            // 从这里开始, 进行真正的图片下载的服务.
            let downloader = options.downloader ?? self.downloader
            let task = downloader.downloadImage(
                with: resource.downloadURL, options: options, completionHandler: _cacheImage
            )
            
            
            // The code below is neat, but it fails the Swift 5.2 compiler with a runtime crash when
            // `BUILD_LIBRARY_FOR_DISTRIBUTION` is turned on. I believe it is a bug in the compiler.
            // Let's fallback to a traditional style before it can be fixed in Swift.
            //
            // https://github.com/onevcat/Kingfisher/issues/1436
            //
            // return task.map(DownloadTask.WrappedTask.download)
            
            if let task = task {
                return .download(task)
            } else {
                return nil
            }
            
        case .provider(let provider):
            provideImage(provider: provider, options: options, completionHandler: _cacheImage)
            return .dataProviding
        }
    }
    
    /// Retrieves image from memory or disk cache.
    ///
    /// - Parameters:
    ///   - source: The target source from which to get image.
    ///   - key: The key to use when caching the image.
    ///   - url: Image request URL. This is not used when retrieving image from cache. It is just used for
    ///          `RetrieveImageResult` callback compatibility.
    ///   - options: Options on how to get the image from image cache.
    ///   - completionHandler: Called when the image retrieving finishes, either with succeeded
    ///                        `RetrieveImageResult` or an error.
    /// - Returns: `true` if the requested image or the original image before being processed is existing in cache.
    ///            Otherwise, this method returns `false`.
    ///
    /// - Note:
    ///    The image retrieving could happen in either memory cache or disk cache. The `.processor` option in
    ///    `options` will be considered when searching in the cache. If no processed image is found, Kingfisher
    ///    will try to check whether an original version of that image is existing or not. If there is already an
    ///    original, Kingfisher retrieves it from cache and processes it. Then, the processed image will be store
    ///    back to cache for later use.
    
    // 这里面的逻辑有点复杂. 但是主要思路就是, 盒子进行传递, 回调进行传递.
    // 然后需要一个返回值, 代表着是否可以从缓存里面进行处理.
    // 如果可以, 那么回调和盒子的传递会有意义, 流程可以继续进行下去. 否则, 流程要在后续的操作进行, 也就是进行图片的下载.
    func retrieveImageFromCache(
        source: Source,
        context: RetrievingContext,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> Bool
    {
        let options = context.options
        // 1. Check whether the image was already in target cache. If so, just get it.
        // 这里会使用到, options 里面的配置. 也就是是否需要使用自己的 cache.
        let targetCache = options.targetCache ?? cache
        let key = source.cacheKey
        // 使用 Cache 类, 来判断, 是否已经缓存了. 
        let targetImageCached = targetCache.imageCachedType(
            forKey: key, processorIdentifier: options.processor.identifier)
        
        let validCache = targetImageCached.cached &&
        (options.fromMemoryCacheOrRefresh == false || targetImageCached == .memory)
        // 这里应该是内存里面的是好值.
        if validCache {
            targetCache.retrieveImage(forKey: key, options: options) { result in
                guard let completionHandler = completionHandler else { return }
                
                // TODO: Optimize it when we can use async across all the project.
                func checkResultImageAndCallback(_ inputImage: KFCrossPlatformImage) {
                    // 可以正常的拿到图片, 将图片变为真正回调需要回传的数据.
                    var image = inputImage
                    if image.kf.imageFrameCount != nil && image.kf.imageFrameCount != 1, let data = image.kf.animatedImageData {
                        // Always recreate animated image representation since it is possible to be loaded in different options.
                        // https://github.com/onevcat/Kingfisher/issues/1923
                        image = options.processor.process(item: .data(data), options: options) ?? .init()
                    }
                    if let modifier = options.imageModifier {
                        image = modifier.modify(image)
                    }
                    let value = result.map {
                        RetrieveImageResult(
                            image: image,
                            cacheType: $0.cacheType,
                            source: source,
                            originalSource: context.originalSource,
                            data: { options.cacheSerializer.data(with: image, original: nil) }
                        )
                    }
                    completionHandler(value)
                }
                
                result.match { cacheResult in
                    options.callbackQueue.execute {
                        // 可以正常的取到 Image 的回调.
                        guard let image = cacheResult.image else {
                            completionHandler(.failure(KingfisherError.cacheError(reason: .imageNotExisting(key: key))))
                            return
                        }
                        
                        if options.cacheSerializer.originalDataUsed {
                            let processor = options.processor
                            // 将对于图片的处理, 放到了获取到原始图片的后面.
                            (options.processingQueue ?? self.processingQueue).execute {
                                let item = ImageProcessItem.image(image)
                                guard let processedImage = processor.process(item: item, options: options) else {
                                    let error = KingfisherError.processorError(
                                        reason: .processingFailed(processor: processor, item: item))
                                    options.callbackQueue.execute { completionHandler(.failure(error)) }
                                    return
                                }
                                options.callbackQueue.execute {
                                    checkResultImageAndCallback(processedImage)
                                }
                            }
                        } else {
                            checkResultImageAndCallback(image)
                        }
                    }
                } onFailure: { error in
                    options.callbackQueue.execute {
                        completionHandler(.failure(KingfisherError.cacheError(reason: .imageNotExisting(key: key))))
                    }
                }
            }
            return true
        }
        
        // 2. Check whether the original image exists. If so, get it, process it, save to storage and return.
        let originalCache = options.originalCache ?? targetCache
        // No need to store the same file in the same cache again.
        if originalCache === targetCache && options.processor == DefaultImageProcessor.default {
            return false
        }
        
        // Check whether the unprocessed image existing or not.
        let originalImageCacheType = originalCache.imageCachedType(
            forKey: key, processorIdentifier: DefaultImageProcessor.default.identifier)
        let canAcceptDiskCache = !options.fromMemoryCacheOrRefresh
        
        let canUseOriginalImageCache =
        (canAcceptDiskCache && originalImageCacheType.cached) ||
        (!canAcceptDiskCache && originalImageCacheType == .memory)
        
        if canUseOriginalImageCache {
            // Now we are ready to get found the original image from cache. We need the unprocessed image, so remove
            // any processor from options first.
            var optionsWithoutProcessor = options
            optionsWithoutProcessor.processor = DefaultImageProcessor.default
            originalCache.retrieveImage(forKey: key, options: optionsWithoutProcessor) { result in
                result.match(
                    onSuccess: { cacheResult in
                        guard let image = cacheResult.image else {
                            assertionFailure("The image (under key: \(key) should be existing in the original cache.")
                            return
                        }
                        
                        let processor = options.processor
                        (options.processingQueue ?? self.processingQueue).execute {
                            let item = ImageProcessItem.image(image)
                            guard let processedImage = processor.process(item: item, options: options) else {
                                let error = KingfisherError.processorError(
                                    reason: .processingFailed(processor: processor, item: item))
                                options.callbackQueue.execute { completionHandler?(.failure(error)) }
                                return
                            }
                            
                            var cacheOptions = options
                            cacheOptions.callbackQueue = .untouch
                            
                            let coordinator = CacheCallbackCoordinator(
                                shouldWaitForCache: options.waitForCache, shouldCacheOriginal: false)
                            
                            let image = options.imageModifier?.modify(processedImage) ?? processedImage
                            let result = RetrieveImageResult(
                                image: image,
                                cacheType: .none,
                                source: source,
                                originalSource: context.originalSource,
                                data: { options.cacheSerializer.data(with: processedImage, original: nil) }
                            )
                            
                            targetCache.store(
                                processedImage,
                                forKey: key,
                                options: cacheOptions,
                                toDisk: !options.cacheMemoryOnly)
                            {
                                _ in
                                coordinator.apply(.cachingImage) {
                                    options.callbackQueue.execute { completionHandler?(.success(result)) }
                                }
                            }
                            
                            coordinator.apply(.cacheInitiated) {
                                options.callbackQueue.execute { completionHandler?(.success(result)) }
                            }
                        }
                    },
                    onFailure: { _ in
                        // This should not happen actually, since we already confirmed `originalImageCached` is `true`.
                        // Just in case...
                        options.callbackQueue.execute {
                            completionHandler?(
                                .failure(KingfisherError.cacheError(reason: .imageNotExisting(key: key)))
                            )
                        }
                    }
                )
            }
            return true
        }
        
        return false
    }
}

// model 盒子, 整个过程的控制, 都存储到了  KingfisherParsedOptionsInfo 里面.
class RetrievingContext {
    
    var options: KingfisherParsedOptionsInfo
    
    let originalSource: Source
    var propagationErrors: [PropagationError] = []
    
    init(options: KingfisherParsedOptionsInfo, originalSource: Source) {
        self.originalSource = originalSource
        self.options = options
    }
    
    func popAlternativeSource() -> Source? {
        guard var alternativeSources = options.alternativeSources, !alternativeSources.isEmpty else {
            return nil
        }
        let nextSource = alternativeSources.removeFirst()
        options.alternativeSources = alternativeSources
        return nextSource
    }
    
    @discardableResult
    func appendError(_ error: KingfisherError, to source: Source) -> [PropagationError] {
        let item = PropagationError(source: source, error: error)
        propagationErrors.append(item)
        return propagationErrors
    }
}

class CacheCallbackCoordinator {
    
    enum State {
        case idle
        case imageCached
        case originalImageCached
        case done
    }
    
    enum Action {
        case cacheInitiated
        case cachingImage
        case cachingOriginalImage
    }
    
    private let shouldWaitForCache: Bool
    private let shouldCacheOriginal: Bool
    private let stateQueue: DispatchQueue
    private var threadSafeState: State = .idle
    
    private (set) var state: State {
        set { stateQueue.sync { threadSafeState = newValue } }
        get { stateQueue.sync { threadSafeState } }
    }
    
    init(shouldWaitForCache: Bool, shouldCacheOriginal: Bool) {
        self.shouldWaitForCache = shouldWaitForCache
        self.shouldCacheOriginal = shouldCacheOriginal
        let stateQueueName = "com.onevcat.Kingfisher.CacheCallbackCoordinator.stateQueue.\(UUID().uuidString)"
        self.stateQueue = DispatchQueue(label: stateQueueName)
    }
    
    func apply(_ action: Action, trigger: () -> Void) {
        switch (state, action) {
        case (.done, _):
            break
            
            // From .idle
        case (.idle, .cacheInitiated):
            if !shouldWaitForCache {
                state = .done
                trigger()
            }
        case (.idle, .cachingImage):
            if shouldCacheOriginal {
                state = .imageCached
            } else {
                state = .done
                trigger()
            }
        case (.idle, .cachingOriginalImage):
            state = .originalImageCached
            
            // From .imageCached
        case (.imageCached, .cachingOriginalImage):
            state = .done
            trigger()
            
            // From .originalImageCached
        case (.originalImageCached, .cachingImage):
            state = .done
            trigger()
            
        default:
            assertionFailure("This case should not happen in CacheCallbackCoordinator: \(state) - \(action)")
        }
    }
}
