
import Foundation

@available(*, deprecated, message: "Typo. Use `AuthenticationChallengeResponsible` instead", renamed: "AuthenticationChallengeResponsible")
public typealias AuthenticationChallengeResponsable = AuthenticationChallengeResponsible

// 声明了一个协议, 然后提供了默认的实现.
// 可以写这样的实现, 然后在 extension 里面, 实现所有的定制点. 可以参考一下之前的 Networking
/// Protocol indicates that an authentication challenge could be handled.
public protocol AuthenticationChallengeResponsible: AnyObject {

    /// Called when a session level authentication challenge is received.
    /// This method provide a chance to handle and response to the authentication
    /// challenge before downloading could start.
    ///
    /// - Parameters:
    ///   - downloader: The downloader which receives this challenge.
    ///   - challenge: An object that contains the request for authentication.
    ///   - completionHandler: A handler that your delegate method must call.
    ///
    /// - Note: This method is a forward from `URLSessionDelegate.urlSession(:didReceiveChallenge:completionHandler:)`.
    ///         Please refer to the document of it in `URLSessionDelegate`.
    
    /// 当收到会话级别的身份验证挑战时调用。
    /// 该方法提供处理和响应身份验证挑战的机会，然后才能开始下载。
    ///
    /// - Parameters:
    ///   - downloader: 接收此挑战的下载器。
    ///   - challenge: 包含身份验证请求的对象。
    ///   - completionHandler: 您的委托方法必须调用的处理程序。
    ///
    /// - Note: 此方法是从 `URLSessionDelegate.urlSession(:didReceiveChallenge:completionHandler:)` 转发而来。
    ///         请参阅 `URLSessionDelegate` 中的文档以获取更多信息。

    func downloader(
        _ downloader: ImageDownloader,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

    /// Called when a task level authentication challenge is received.
    /// This method provide a chance to handle and response to the authentication
    /// challenge before downloading could start.
    ///
    /// - Parameters:
    ///   - downloader: The downloader which receives this challenge.
    ///   - task: The task whose request requires authentication.
    ///   - challenge: An object that contains the request for authentication.
    ///   - completionHandler: A handler that your delegate method must call.
    ///
    /// 当收到任务级别的身份验证挑战时调用。
    /// 该方法提供处理和响应身份验证挑战的机会，确保在开始下载之前进行处理。
    ///
    /// - Parameters:
    ///   - downloader: 接收此挑战的下载器。
    ///   - task: 需要身份验证的请求所属的任务。
    ///   - challenge: 包含身份验证请求的对象。
    ///   - completionHandler: 您的委托方法必须调用的处理程序。

    func downloader(
        _ downloader: ImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

// 默认实现, 都是进行使用 performDefaultHandling.
extension AuthenticationChallengeResponsible {

    public func downloader(
        _ downloader: ImageDownloader,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // 如果是服务器的验证, 那么设计了一套 trustedHosts, 可以实现自签名证书
            if let trustedHosts = downloader.trustedHosts,
                trustedHosts.contains(challenge.protectionSpace.host) {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, credential)
                return
            }
        }

        completionHandler(.performDefaultHandling, nil)
    }

    public func downloader(
        _ downloader: ImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        completionHandler(.performDefaultHandling, nil)
    }

}
