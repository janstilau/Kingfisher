
import Foundation

/// Represents and wraps a method for modifying request before an image download request starts in an asynchronous way.
/// 表示并封装了在图像下载请求开始之前以异步方式修改请求的方法。
public protocol AsyncImageDownloadRequestModifier {

    /// This method will be called just before the `request` being sent.
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    /// When you have done with the modification, call the `reportModified` block with the modified request and the data
    /// download will happen with this request.
    ///
    /// Usually, you pass an `AsyncImageDownloadRequestModifier` as the associated value of
    /// `KingfisherOptionsInfoItem.requestModifier` and use it as the `options` parameter in related methods.
    ///
    /// If you do nothing with the input `request` and return it as is, a downloading process will start with it.
    ///
    /// - Parameters:
    ///   - request: The input request contains necessary information like `url`. This request is generated
    ///              according to your resource url as a GET request.
    ///   - reportModified: The callback block you need to call after the asynchronous modifying done.
    
    /*
     这个方法将在发送request之前调用。这是你最后一次修改图像下载请求的机会。你可以为自定义目的修改请求，例如在头部添加身份验证令牌，进行基本的HTTP身份验证，或执行类似URL映射的操作。当你完成修改时，请使用修改后的请求和数据调用reportModified块，下载将使用这个请求进行。

     通常，你将AsyncImageDownloadRequestModifier作为KingfisherOptionsInfoItem.requestModifier的关联值传递，并在相关方法中将其用作options参数。

     如果你对输入的request什么都不做并将其原样返回，将会使用它开始下载过程。

     参数：
     request：输入请求包含诸如url之类的必要信息。该请求是根据你的资源URL生成的GET请求。
     reportModified：异步修改完成后需要调用的回调块。
     */
    func modified(for request: URLRequest, reportModified: @escaping (URLRequest?) -> Void)

    /// A block will be called when the download task started.
    ///
    /// If an `AsyncImageDownloadRequestModifier` and the asynchronous modification happens before the download, the
    /// related download method will not return a valid `DownloadTask` value. Instead, you can get one from this method.
    var onDownloadTaskStarted: ((DownloadTask?) -> Void)? { get }
}

/// Represents and wraps a method for modifying request before an image download request starts.
public protocol ImageDownloadRequestModifier: AsyncImageDownloadRequestModifier {

    /// This method will be called just before the `request` being sent.
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    ///
    /// Usually, you pass an `ImageDownloadRequestModifier` as the associated value of
    /// `KingfisherOptionsInfoItem.requestModifier` and use it as the `options` parameter in related methods.
    ///
    /// If you do nothing with the input `request` and return it as is, a downloading process will start with it.
    ///
    /// - Parameter request: The input request contains necessary information like `url`. This request is generated
    ///                      according to your resource url as a GET request.
    /// - Returns: A modified version of request, which you wish to use for downloading an image. If `nil` returned,
    ///            a `KingfisherError.requestError` with `.emptyRequest` as its reason will occur.
    ///
    /*
     这个方法将在发送request之前调用。这是你最后一次修改图像下载请求的机会。你可以为自定义目的修改请求，例如在头部添加身份验证令牌，进行基本的HTTP身份验证，或执行类似URL映射的操作。

     通常，你将ImageDownloadRequestModifier作为KingfisherOptionsInfoItem.requestModifier的关联值传递，并在相关方法中将其用作options参数。

     如果你对输入的request什么都不做并将其原样返回，将会使用它开始下载过程。

     参数：
     request：输入请求包含诸如url之类的必要信息。该请求是根据你的资源URL生成的GET请求。
     返回：一个修改后的请求版本，你希望用它来下载图像。如果返回nil，将会发生KingfisherError.requestError，其原因是.emptyRequest。
     */
    func modified(for request: URLRequest) -> URLRequest?
}

// ImageDownloadRequestModifier 这个 protocol, 不仅仅是 protocol 的继承.
// 更多的是, 他是对 BaseProtocol 进行默认的实现. 
extension ImageDownloadRequestModifier {
    public func modified(for request: URLRequest, reportModified: @escaping (URLRequest?) -> Void) {
        let request = modified(for: request)
        reportModified(request)
    }

    /// This is `nil` for a sync `ImageDownloadRequestModifier` by default. You can get the `DownloadTask` from the
    /// return value of downloader method.
    public var onDownloadTaskStarted: ((DownloadTask?) -> Void)? { return nil }
}

/// A wrapper for creating an `ImageDownloadRequestModifier` easier.
/// This type conforms to `ImageDownloadRequestModifier` and wraps an image modify block.
public struct AnyModifier: ImageDownloadRequestModifier {
    
    let block: (URLRequest) -> URLRequest?

    /// For `ImageDownloadRequestModifier` conformation.
    public func modified(for request: URLRequest) -> URLRequest? {
        return block(request)
    }
    
    /// Creates a value of `ImageDownloadRequestModifier` which runs `modify` block.
    ///
    /// - Parameter modify: The request modifying block runs when a request modifying task comes.
    ///                     The return `URLRequest?` value of this block will be used as the image download request.
    ///                     If `nil` returned, a `KingfisherError.requestError` with `.emptyRequest` as its
    ///                     reason will occur.
    public init(modify: @escaping (URLRequest) -> URLRequest?) {
        block = modify
    }
}
