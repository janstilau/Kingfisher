
#if os(macOS)
import AppKit
#else
import UIKit
#endif
    

/// KingfisherOptionsInfo is a typealias for [KingfisherOptionsInfoItem].
/// You can use the enum of option item with value to control some behaviors of Kingfisher.
public typealias KingfisherOptionsInfo = [KingfisherOptionsInfoItem]

extension Array where Element == KingfisherOptionsInfoItem {
    static let empty: KingfisherOptionsInfo = []
}

/// Represents the available option items could be used in `KingfisherOptionsInfo`.
// 将所有的数据, 都包装成为 KingfisherOptionsInfoItem, 更多的是想用 KingfisherOptionsInfo, 也就是数组的方式供外界使用.

// 这是一个非常非常好的使用方式, 在自己的 URLParams 里面, 使用到了这种模式.

// 大部分的 Case, 都是存储一个 Protocol. 这样就提供了变化的可能了.
public enum KingfisherOptionsInfoItem {
    
    /// Kingfisher will use the associated `ImageCache` object when handling related operations,
    /// including trying to retrieve the cached images and store the downloaded image to it.
    
    /// 在处理相关操作时，Kingfisher 将使用关联的 `ImageCache` 对象，其中包括尝试检索缓存的图像以及将下载的图像存储到其中。
    case targetCache(ImageCache)
    
    /// The `ImageCache` for storing and retrieving original images. If `originalCache` is
    /// contained in the options, it will be preferred for storing and retrieving original images.
    /// If there is no `.originalCache` in the options, `.targetCache` will be used to store original images.
    ///
    /// When using KingfisherManager to download and store an image, if `cacheOriginalImage` is
    /// applied in the option, the original image will be stored to this `originalCache`. At the
    /// same time, if a requested final image (with processor applied) cannot be found in `targetCache`,
    /// Kingfisher will try to search the original image to check whether it is already there. If found,
    /// it will be used and applied with the given processor. It is an optimization for not downloading
    /// the same image for multiple times.
    /// `ImageCache` 用于存储和检索原始图像。如果选项中包含 `originalCache`，将优先使用它来存储和检索原始图像。
    /// 如果选项中没有 `.originalCache`，将使用 `.targetCache` 来存储原始图像。
    ///
    /// 当使用 KingfisherManager 下载和存储图像时，如果在选项中应用了 `cacheOriginalImage`，则原始图像将被存储到 `originalCache` 中。
    /// 同时，如果在 `targetCache` 中找不到已应用处理器的请求的最终图像，Kingfisher 将尝试搜索原始图像以检查是否已存在。
    /// 如果找到，将使用该图像并应用给定的处理器。这是一种优化，避免为同一图像多次下载。
    case originalCache(ImageCache)
    
    /// Kingfisher will use the associated `ImageDownloader` object to download the requested images.
    case downloader(ImageDownloader)

    /// Member for animation transition when using `UIImageView`. Kingfisher will use the `ImageTransition` of
    /// this enum to animate the image in if it is downloaded from web. The transition will not happen when the
    /// image is retrieved from either memory or disk cache by default. If you need to do the transition even when
    /// the image being retrieved from cache, set `.forceRefresh` as well.
    
    /// 用于在使用 `UIImageView` 时进行动画过渡的成员。Kingfisher 将使用此枚举的 `ImageTransition` 来为从网络下载的图像执行动画。
    /// 默认情况下，当图像从内存或磁盘缓存中检索时，不会发生过渡。如果需要在从缓存中检索图像时执行过渡，请同时设置 `.forceRefresh`。
    case transition(ImageTransition)
    
    /// Associated `Float` value will be set as the priority of image download task. The value for it should be
    /// between 0.0~1.0. If this option not set, the default value (`URLSessionTask.defaultPriority`) will be used.
    
    /// 关联的 `Float` 值将被设置为图像下载任务的优先级。其值应在 0.0 到 1.0 之间。如果未设置此选项，将使用默认值（`URLSessionTask.defaultPriority`）。
    case downloadPriority(Float)
    
    /// If set, Kingfisher will ignore the cache and try to start a download task for the image source.
    // 强制使用网络请求数据.
    case forceRefresh

    /// If set, Kingfisher will try to retrieve the image from memory cache first. If the image is not in memory
    /// cache, then it will ignore the disk cache but download the image again from network. This is useful when
    /// you want to display a changeable image behind the same url at the same app session, while avoiding download
    /// it for multiple times.
    
    /// 从这里来看, 应该是同样的一个 URL, 可能会更改图片. 不过从来没用过.
    /// 如果设置，Kingfisher 将首先尝试从内存缓存中检索图像。如果图像不在内存缓存中，它将忽略磁盘缓存，而从网络重新下载图像。
    /// 当你想在同一应用程序会话中在相同的 URL 背后显示一个可变的图像，同时避免多次下载它时，这是非常有用的。
    case fromMemoryCacheOrRefresh
    
    /// If set, setting the image to an image view will happen with transition even when retrieved from cache.
    /// See `.transition` option for more.
    // 默认从缓存里面获取到的数据, 不会有动画的效果.
    case forceTransition
    
    /// If set, Kingfisher will only cache the value in memory but not in disk.
    case cacheMemoryOnly
    
    /// If set, Kingfisher will wait for caching operation to be completed before calling the completion block.
    // 默认其实不会等待缓存, 然后调用回调了闭包了.
    case waitForCache
    
    /// If set, Kingfisher will only try to retrieve the image from cache, but not from network. If the image is not in
    /// cache, the image retrieving will fail with the `KingfisherError.cacheError` with `.imageNotExisting` as its
    /// reason.
    // 不下载了.
    case onlyFromCache
    
    /// Decode the image in background thread before using. It will decode the downloaded image data and do a off-screen
    /// rendering to extract pixel information in background. This can speed up display, but will cost more time to
    /// prepare the image for using.
    ///
    /// 在使用之前在后台线程中解码图像。它将在后台解码下载的图像数据，并执行离屏渲染以提取像素信息。这可以加速显示，但会花费更多时间来准备图像以供使用。
    // 离屏渲染????
    case backgroundDecode

    /// The associated value will be used as the target queue of dispatch callbacks when retrieving images from
    /// cache. If not set, Kingfisher will use `.mainCurrentOrAsync` for callbacks.
    ///
    /// - Note:
    /// This option does not affect the callbacks for UI related extension methods. You will always get the
    /// callbacks called from main queue.
    
    /// 关联值将用作从缓存中检索图像时调度回调的目标队列。如果未设置，Kingfisher 将在回调中使用 `.mainCurrentOrAsync`。
    ///
    /// - 注意：
    /// 此选项不会影响与 UI 相关的扩展方法的回调。你将始终从主队列中获取回调。
    case callbackQueue(CallbackQueue)
    
    /// The associated value will be used as the scale factor when converting retrieved data to an image.
    /// Specify the image scale, instead of your screen scale. You may need to set the correct scale when you dealing
    /// with 2x or 3x retina images. Otherwise, Kingfisher will convert the data to image object at `scale` 1.0.
    // 这里 SDWebImage 和 KF 的处理策略不太一致.
    /// 关联值将在将检索到的数据转换为图像时用作比例因子。指定图像的比例，而不是屏幕的比例。当处理 2x 或 3x 的 retina 图像时，你可能需要设置正确的比例。
    /// 否则，Kingfisher 将在 `scale` 为 1.0 时将数据转换为图像对象。
    case scaleFactor(CGFloat)

    /// Whether all the animated image data should be preloaded. Default is `false`, which means only following frames
    /// will be loaded on need. If `true`, all the animated image data will be loaded and decoded into memory.
    ///
    /// This option is mainly used for back compatibility internally. You should not set it directly. Instead,
    /// you should choose the image view class to control the GIF data loading. There are two classes in Kingfisher
    /// support to display a GIF image. `AnimatedImageView` does not preload all data, it takes much less memory, but
    /// uses more CPU when display. While a normal image view (`UIImageView` or `NSImageView`) loads all data at once,
    /// which uses more memory but only decode image frames once.
    /// 是否应该预加载所有动画图像数据。默认值为 `false`，这意味着只有在需要时加载后续帧。如果为 `true`，将加载并解码所有动画图像数据到内存中。
    ///
    /// 此选项主要用于内部向后兼容性。不建议直接设置它。相反，应选择图像视图类来控制 GIF 数据的加载。Kingfisher 中有两个支持显示 GIF 图像的类。
    /// `AnimatedImageView` 不会预加载所有数据，占用较少的内存，但在显示时使用更多的 CPU。而普通的图像视图（`UIImageView` 或 `NSImageView`）一次加载所有数据，
    /// 占用更多的内存，但只解码图像帧一次。
    case preloadAllAnimationData
    
    /// The `ImageDownloadRequestModifier` contained will be used to change the request before it being sent.
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    /// The original request will be sent without any modification by default.
    /// 包含的 `ImageDownloadRequestModifier` 将用于在发送请求之前更改请求。这是修改图像下载请求的最后机会。
    /// 可以为一些自定义目的修改请求，比如向头部添加身份验证令牌、执行基本的 HTTP 身份验证或进行 URL 映射。
    /// 默认情况下，原始请求将不会被任何修改而被发送。
    // 进行下载的 Request 的修改.
    case requestModifier(AsyncImageDownloadRequestModifier)
    
    /// The `ImageDownloadRedirectHandler` contained will be used to change the request before redirection.
    /// This is the possibility you can modify the image download request during redirect. You can modify the request for
    /// some customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url
    /// mapping.
    /// The original redirection request will be sent without any modification by default.
    /// 包含的 `ImageDownloadRedirectHandler` 将用于在重定向之前更改请求。这是在重定向期间修改图像下载请求的可能性。
    /// 可以为一些自定义目的修改请求，比如向头部添加身份验证令牌、执行基本的 HTTP 身份验证或进行 URL 映射。
    /// 默认情况下，原始重定向请求将不会被任何修改而被发送。
    // 可以使用这些, 完成 App 范围内的相关配置.
    case redirectHandler(ImageDownloadRedirectHandler)
    
    /// Processor for processing when the downloading finishes, a processor will convert the downloaded data to an image
    /// and/or apply some filter on it. If a cache is connected to the downloader (it happens when you are using
    /// KingfisherManager or any of the view extension methods), the converted image will also be sent to cache as well.
    /// If not set, the `DefaultImageProcessor.default` will be used.
    /// 在下载完成后进行处理的处理器，该处理器将把下载的数据转换为图像并/或对其应用一些过滤器。
    /// 如果与下载器连接了缓存（当使用 KingfisherManager 或任何视图扩展方法时会发生），转换后的图像也将被发送到缓存中。
    /// 如果未设置，将使用 `DefaultImageProcessor.default`。
    case processor(ImageProcessor)
    
    /// Provides a `CacheSerializer` to convert some data to an image object for
    /// retrieving from disk cache or vice versa for storing to disk cache.
    /// If not set, the `DefaultCacheSerializer.default` will be used.
    /// 提供一个 `CacheSerializer` 以将一些数据转换为图像对象，以从磁盘缓存中检索，或者反之，以将图像对象存储到磁盘缓存。
    /// 如果未设置，将使用 `DefaultCacheSerializer.default`。
    case cacheSerializer(CacheSerializer)

    /// An `ImageModifier` is for modifying an image as needed right before it is used. If the image was fetched
    /// directly from the downloader, the modifier will run directly after the `ImageProcessor`. If the image is being
    /// fetched from a cache, the modifier will run after the `CacheSerializer`.
    ///
    /// Use `ImageModifier` when you need to set properties that do not persist when caching the image on a concrete
    /// type of `Image`, such as the `renderingMode` or the `alignmentInsets` of `UIImage`.
    /// 用于在图像使用之前根据需要修改图像的 `ImageModifier`。如果图像直接从下载器获取，修改器将直接在 `ImageProcessor` 之后运行。
    /// 如果图像是从缓存获取的，修改器将在 `CacheSerializer` 之后运行。
    /// 使用 `ImageModifier` 当你需要设置不在缓存图像时保留的属性时，比如 `UIImage` 的 `renderingMode` 或 `alignmentInsets`。
    case imageModifier(ImageModifier)
    
    /// Keep the existing image of image view while setting another image to it.
    /// By setting this option, the placeholder image parameter of image view extension method
    /// will be ignored and the current image will be kept while loading or downloading the new image.
    /// 在设置新图像时保留图像视图的现有图像。通过设置此选项，将忽略图像视图扩展方法的占位图参数，并在加载或下载新图像时保留当前图像。
    case keepCurrentImageWhileLoading
    
    /// If set, Kingfisher will only load the first frame from an animated image file as a single image.
    /// Loading an animated images may take too much memory. It will be useful when you want to display a
    /// static preview of the first frame from an animated image.
    ///
    /// This option will be ignored if the target image is not animated image data.
    /// 如果设置，Kingfisher 将仅从动画图像文件加载第一帧作为单个图像。加载动画图像可能占用太多内存。
    /// 当你想要显示动画图像的第一帧的静态预览时，这将很有用。
    /// 如果目标图像不是动画图像数据，将忽略此选项。
    case onlyLoadFirstFrame
    
    /// If set and an `ImageProcessor` is used, Kingfisher will try to cache both the final result and original
    /// image. Kingfisher will have a chance to use the original image when another processor is applied to the same
    /// resource, instead of downloading it again. You can use `.originalCache` to specify a cache or the original
    /// images if necessary.
    ///
    /// The original image will be only cached to disk storage.
    /// 如果设置，并且使用了 `ImageProcessor`，Kingfisher 将尝试同时缓存最终结果和原始图像。
    /// 当同一资源被应用了另一个处理器时，Kingfisher 将有机会使用原始图像，而不是再次下载它。
    /// 如果需要，可以使用 `.originalCache` 来指定缓存或原始图像。
    /// 原始图像将仅缓存到磁盘存储。
    case cacheOriginalImage
    
    /// If set and an image retrieving error occurred Kingfisher will set provided image (or empty)
    /// in place of requested one. It's useful when you don't want to show placeholder
    /// during loading time but wants to use some default image when requests will be failed.
    /// 如果设置，并且在图像检索过程中发生了错误，Kingfisher 将设置提供的图像（或空图像）代替请求的图像。
    /// 当你不想在加载时间显示占位图，但希望在请求失败时使用默认图像时，这将很有用。
    case onFailureImage(KFCrossPlatformImage?)
    
    /// If set and used in `ImagePrefetcher`, the prefetching operation will load the images into memory storage
    /// aggressively. By default this is not contained in the options, that means if the requested image is already
    /// in disk cache, Kingfisher will not try to load it to memory.
    /// 如果设置并在 `ImagePrefetcher` 中使用，预取操作将主动将图像加载到内存存储中。
    /// 默认情况下，这不包含在选项中，这意味着如果请求的图像已经在磁盘缓存中，则 Kingfisher 将不尝试将其加载到内存中。
    case alsoPrefetchToMemory
    
    /// If set, the disk storage loading will happen in the same calling queue. By default, disk storage file loading
    /// happens in its own queue with an asynchronous dispatch behavior. Although it provides better non-blocking disk
    /// loading performance, it also causes a flickering when you reload an image from disk, if the image view already
    /// has an image set.
    ///
    /// Set this options will stop that flickering by keeping all loading in the same queue (typically the UI queue
    /// if you are using Kingfisher's extension methods to set an image), with a tradeoff of loading performance.
    /*
     如果设置，磁盘存储加载将在同一调用队列中进行。默认情况下，磁盘存储文件加载在其自己的队列中，具有异步调度行为。尽管它提供更好的非阻塞磁盘加载性能，但如果重新从磁盘重新加载图像，如果图像视图已经设置了图像，则会引起闪烁。
     设置此选项将通过在同一个队列中保持所有加载（通常是 UI 队列，如果您正在使用 Kingfisher 的扩展方法设置图像）来停止闪烁，但会有加载性能的折衷。
     */
    case loadDiskFileSynchronously

    /// Options to control the writing of data to disk storage
    /// If set, options will be passed the store operation for a new files.
    /*
     控制将数据写入磁盘存储的选项。如果设置，选项将传递给存储操作以用于新文件。
     */
    case diskStoreWriteOptions(Data.WritingOptions)

    /// The expiration setting for memory cache. By default, the underlying `MemoryStorage.Backend` uses the
    /// expiration in its config for all items. If set, the `MemoryStorage.Backend` will use this associated
    /// value to overwrite the config setting for this caching item.
    /*
     内存缓存的过期设置。默认情况下，底层的 MemoryStorage.Backend 对所有项目使用其配置中的过期时间。如果设置，MemoryStorage.Backend 将使用此关联值覆盖此缓存项目的配置设置。
     */
    case memoryCacheExpiration(StorageExpiration)
    
    /// The expiration extending setting for memory cache. The item expiration time will be incremented by this
    /// value after access.
    /// By default, the underlying `MemoryStorage.Backend` uses the initial cache expiration as extending
    /// value: .cacheTime.
    ///
    /// To disable extending option at all add memoryCacheAccessExtendingExpiration(.none) to options.
    /*
     内存缓存的过期扩展设置。在访问后，项目的过期时间将按照此值增加。
     默认情况下，底层的 MemoryStorage.Backend 使用初始缓存过期时间作为扩展值：.cacheTime。
     若要完全禁用扩展选项，请将 memoryCacheAccessExtendingExpiration(.none) 添加到选项中。
     */
    case memoryCacheAccessExtendingExpiration(ExpirationExtending)
    
    /// The expiration setting for disk cache. By default, the underlying `DiskStorage.Backend` uses the
    /// expiration in its config for all items. If set, the `DiskStorage.Backend` will use this associated
    /// value to overwrite the config setting for this caching item.
    /*
     磁盘缓存的过期设置。默认情况下，底层的 DiskStorage.Backend 对所有项目使用其配置中的过期时间。如果设置，DiskStorage.Backend 将使用此关联值覆盖此缓存项目的配置设置。
     */
    case diskCacheExpiration(StorageExpiration)

    /// The expiration extending setting for disk cache. The item expiration time will be incremented by this value after access.
    /// By default, the underlying `DiskStorage.Backend` uses the initial cache expiration as extending value: .cacheTime.
    /// To disable extending option at all add diskCacheAccessExtendingExpiration(.none) to options.
    /*
     '磁盘缓存的过期扩展设置。在访问后，项目的过期时间将按照此值增加。
     默认情况下，底层的 DiskStorage.Backend 使用初始缓存过期时间作为扩展值：.cacheTime。
     若要完全禁用扩展选项，请将 diskCacheAccessExtendingExpiration(.none) 添加到选项中。
     */
    case diskCacheAccessExtendingExpiration(ExpirationExtending)
    
    /// Decides on which queue the image processing should happen. By default, Kingfisher uses a pre-defined serial
    /// queue to process images. Use this option to change this behavior. For example, specify a `.mainCurrentOrAsync`
    /// to let the image be processed in main queue to prevent a possible flickering (but with a possibility of
    /// blocking the UI, especially if the processor needs a lot of time to run).
    /*
     决定图像处理应该在哪个队列中进行。默认情况下，Kingfisher 使用预定义的串行队列来处理图像。使用此选项更改此行为。
     */
    case processingQueue(CallbackQueue)
    
    /// Enable progressive image loading, Kingfisher will use the associated `ImageProgressive` value to process the
    /// progressive JPEG data and display it in a progressive way.
    case progressiveJPEG(ImageProgressive)

    /// The alternative sources will be used when the original input `Source` fails. The `Source`s in the associated
    /// array will be used to start a new image loading task if the previous task fails due to an error. The image
    /// source loading process will stop as soon as a source is loaded successfully. If all `[Source]`s are used but
    /// the loading is still failing, an `imageSettingError` with `alternativeSourcesExhausted` as its reason will be
    /// thrown out.
    ///
    /// This option is useful if you want to implement a fallback solution for setting image.
    ///
    /// User cancellation will not trigger the alternative source loading.
    case alternativeSources([Source])

    /// Provide a retry strategy which will be used when something gets wrong during the image retrieving process from
    /// `KingfisherManager`. You can define a strategy by create a type conforming to the `RetryStrategy` protocol.
    ///
    /// - Note:
    ///
    /// All extension methods of Kingfisher (`kf` extensions on `UIImageView` or `UIButton`) retrieve images through
    /// `KingfisherManager`, so the retry strategy also applies when using them. However, this option does not apply
    /// when pass to an `ImageDownloader` or `ImageCache`.
    ///
    case retryStrategy(RetryStrategy)

    /// The `Source` should be loaded when user enables Low Data Mode and the original source fails with an
    /// `NSURLErrorNetworkUnavailableReason.constrained` error. When this option is set, the
    /// `allowsConstrainedNetworkAccess` property of the request for the original source will be set to `false` and the
    /// `Source` in associated value will be used to retrieve the image for low data mode. Usually, you can provide a
    /// low-resolution version of your image or a local image provider to display a placeholder.
    ///
    /// If not set or the `source` is `nil`, the device Low Data Mode will be ignored and the original source will
    /// be loaded following the system default behavior, in a normal way.
    case lowDataMode(Source?)
    
    
    /*
     processingQueue:
     决定图像处理应该在哪个队列中进行。默认情况下，Kingfisher 使用预定义的串行队列来处理图像。使用此选项更改此行为。
     progressiveJPEG:
     启用渐进式图像加载，Kingfisher 将使用关联的 ImageProgressive 值来处理渐进式 JPEG 数据并以渐进式方式显示它。
     alternativeSources:
     当原始输入 Source 失败时，将使用替代源。关联数组中的 Source 将用于启动新的图像加载任务，如果由于错误导致上一个任务失败，则图像源加载过程将在加载成功时立即停止。
     retryStrategy:
     在从 KingfisherManager 检索图像的过程中出现问题时提供的重试策略。您可以创建符合 RetryStrategy 协议的类型来定义策略。
     lowDataMode:
     当用户启用低数据模式并且原始源由于 NSURLErrorNetworkUnavailableReason.constrained 错误而失败时，应加载的 Source。如果设置了此选项，原始源的请求的 allowsConstrainedNetworkAccess 属性将设置为 false，并且将使用关联值中的 Source 在低数据模式下检索图像。通常，您可以提供图像的低分辨率版本或本地图像提供程序来显示占位符。
     如果未设置或 source 为 nil，则会忽略设备的低数据模式，并按照系统的默认行为正常加载原始源。
     */
}

/*
 KingfisherOptionsInfoItem 是一组可选项的定义，而 KingfisherParsedOptionsInfo 是这些选项的解析结果，它包含了具体的配置信息。当你使用 Kingfisher 库的方法时，你可以通过传递 KingfisherOptionsInfo 对象来配置各种选项，而库内部则会将其解析为 KingfisherParsedOptionsInfo 以方便处理。
 
 虽然直接使用 KingfisherParsedOptionsInfo 也是可能的，但引入 KingfisherOptionsInfo 的设计使得使用者可以更自然地配置选项，而无需关心内部的具体解析细节。这样的设计可以在提供灵活性的同时，通过解析过程进行性能上的优化。
 
 从我个人的理解是, KingfisherParsedOptionsInfo 是一个需要大量配置的类, 但是 KingfisherOptionsInfoItem 是一个只需要极小的代价配置的类.
 在真正使用的时候, 传递一个比较简单的数据, 要比传递一个庞大的数据要好用的多, 就算这个庞大的数据有各种默认值, 将这个放大的数据暴露出去, 也不是一个好的方式.
 */

// Improve performance by parsing the input `KingfisherOptionsInfo` (self) first.
// So we can prevent the iterating over the options array again and again.
/// The parsed options info used across Kingfisher methods. Each property in this type corresponds a case member
/// in `KingfisherOptionsInfoItem`. When a `KingfisherOptionsInfo` sent to Kingfisher related methods, it will be
/// parsed and converted to a `KingfisherParsedOptionsInfo` first, and pass through the internal methods.

/// 用于在 Kingfisher 方法中传递的已解析的选项信息。该类型中的每个属性对应于 `KingfisherOptionsInfoItem` 中的一个 case 成员。
/// 当一个 `KingfisherOptionsInfo` 传递给与 Kingfisher 相关的方法时，首先会将其解析并转换为 `KingfisherParsedOptionsInfo`，
/// 然后通过内部方法传递。

// 各种的功能类, 聚集到了这类里面. 然后所有的各种操作, 都在使用 KingfisherParsedOptionsInfo 做传递.
public struct KingfisherParsedOptionsInfo {

    public var targetCache: ImageCache? = nil
    public var originalCache: ImageCache? = nil
    public var downloader: ImageDownloader? = nil
    public var transition: ImageTransition = .none
    public var downloadPriority: Float = URLSessionTask.defaultPriority
    public var forceRefresh = false
    public var fromMemoryCacheOrRefresh = false
    public var forceTransition = false
    public var cacheMemoryOnly = false
    public var waitForCache = false
    public var onlyFromCache = false
    public var backgroundDecode = false
    public var preloadAllAnimationData = false
    public var callbackQueue: CallbackQueue = .mainCurrentOrAsync
    public var scaleFactor: CGFloat = 1.0
    public var requestModifier: AsyncImageDownloadRequestModifier? = nil
    public var redirectHandler: ImageDownloadRedirectHandler? = nil
    public var processor: ImageProcessor = DefaultImageProcessor.default
    public var imageModifier: ImageModifier? = nil
    public var cacheSerializer: CacheSerializer = DefaultCacheSerializer.default
    public var keepCurrentImageWhileLoading = false
    public var onlyLoadFirstFrame = false
    public var cacheOriginalImage = false
    public var onFailureImage: Optional<KFCrossPlatformImage?> = .none
    public var alsoPrefetchToMemory = false
    public var loadDiskFileSynchronously = false
    public var diskStoreWriteOptions: Data.WritingOptions = []
    public var memoryCacheExpiration: StorageExpiration? = nil
    public var memoryCacheAccessExtendingExpiration: ExpirationExtending = .cacheTime
    public var diskCacheExpiration: StorageExpiration? = nil
    public var diskCacheAccessExtendingExpiration: ExpirationExtending = .cacheTime
    public var processingQueue: CallbackQueue? = nil
    public var progressiveJPEG: ImageProgressive? = nil
    public var alternativeSources: [Source]? = nil
    public var retryStrategy: RetryStrategy? = nil
    public var lowDataModeSource: Source? = nil

    var onDataReceived: [DataReceivingSideEffect]? = nil
    
    // 将各种 Enum 的数组的解析, 放到了初始化方法的内部.
    public init(_ info: KingfisherOptionsInfo?) {
        guard let info = info else { return }
        for option in info {
            switch option {
            case .targetCache(let value): targetCache = value
            case .originalCache(let value): originalCache = value
            case .downloader(let value): downloader = value
            case .transition(let value): transition = value
            case .downloadPriority(let value): downloadPriority = value
            case .forceRefresh: forceRefresh = true
            case .fromMemoryCacheOrRefresh: fromMemoryCacheOrRefresh = true
            case .forceTransition: forceTransition = true
            case .cacheMemoryOnly: cacheMemoryOnly = true
            case .waitForCache: waitForCache = true
            case .onlyFromCache: onlyFromCache = true
            case .backgroundDecode: backgroundDecode = true
            case .preloadAllAnimationData: preloadAllAnimationData = true
            case .callbackQueue(let value): callbackQueue = value
            case .scaleFactor(let value): scaleFactor = value
            case .requestModifier(let value): requestModifier = value
            case .redirectHandler(let value): redirectHandler = value
            case .processor(let value): processor = value
            case .imageModifier(let value): imageModifier = value
            case .cacheSerializer(let value): cacheSerializer = value
            case .keepCurrentImageWhileLoading: keepCurrentImageWhileLoading = true
            case .onlyLoadFirstFrame: onlyLoadFirstFrame = true
            case .cacheOriginalImage: cacheOriginalImage = true
            case .onFailureImage(let value): onFailureImage = .some(value)
            case .alsoPrefetchToMemory: alsoPrefetchToMemory = true
            case .loadDiskFileSynchronously: loadDiskFileSynchronously = true
            case .diskStoreWriteOptions(let options): diskStoreWriteOptions = options
            case .memoryCacheExpiration(let expiration): memoryCacheExpiration = expiration
            case .memoryCacheAccessExtendingExpiration(let expirationExtending): memoryCacheAccessExtendingExpiration = expirationExtending
            case .diskCacheExpiration(let expiration): diskCacheExpiration = expiration
            case .diskCacheAccessExtendingExpiration(let expirationExtending): diskCacheAccessExtendingExpiration = expirationExtending
            case .processingQueue(let queue): processingQueue = queue
            case .progressiveJPEG(let value): progressiveJPEG = value
            case .alternativeSources(let sources): alternativeSources = sources
            case .retryStrategy(let strategy): retryStrategy = strategy
            case .lowDataMode(let source): lowDataModeSource = source
            }
        }

        if originalCache == nil {
            originalCache = targetCache
        }
    }
}

extension KingfisherParsedOptionsInfo {
    var imageCreatingOptions: ImageCreatingOptions {
        return ImageCreatingOptions(
            scale: scaleFactor,
            duration: 0.0,
            preloadAll: preloadAllAnimationData,
            onlyFirstFrame: onlyLoadFirstFrame)
    }
}

protocol DataReceivingSideEffect: AnyObject {
    var onShouldApply: () -> Bool { get set }
    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data)
}

class ImageLoadingProgressSideEffect: DataReceivingSideEffect {

    var onShouldApply: () -> Bool = { return true }
    
    let block: DownloadProgressBlock

    init(_ block: @escaping DownloadProgressBlock) {
        self.block = block
    }

    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data) {
        guard self.onShouldApply() else { return }
        guard let expectedContentLength = task.task.response?.expectedContentLength,
                  expectedContentLength != -1 else
        {
            return
        }

        let dataLength = Int64(task.mutableData.count)
        DispatchQueue.main.async {
            self.block(dataLength, expectedContentLength)
        }
    }
}
