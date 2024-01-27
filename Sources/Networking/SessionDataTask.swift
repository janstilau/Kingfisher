
import Foundation

/// Represents a session data task in `ImageDownloader`. It consists of an underlying `URLSessionDataTask` and
/// an array of `TaskCallback`. Multiple `TaskCallback`s could be added for a single downloading data task.

public class SessionDataTask {

    /// Represents the type of token which used for cancelling a task.
    public typealias CancelToken = Int

    struct TaskCallback {
        // 对于 Image 来说, 他就记录最后 Complete 的回调.
        // Result<ImageLoadingResult, KingfisherError> 是 Input
        // Void 是 Output.
        let onCompleted: Delegate<Result<ImageLoadingResult, KingfisherError>, Void>?
        // KingfisherParsedOptionsInfo 就是一个大盒子. 虽然下载里面, 可能只是用到其中一部分的数据, 但是这个盒子在整个流程里面运转, 会让逻辑更加的简介.
        let options: KingfisherParsedOptionsInfo
    }

    /// Downloaded raw data of current task.
    public private(set) var mutableData: Data

    // This is a copy of `task.originalRequest?.url`. It is for getting a race-safe behavior for a pitfall on iOS 13.
    // Ref: https://github.com/onevcat/Kingfisher/issues/1511
    public let originalURL: URL?

    /// The underlying download task. It is only for debugging purpose when you encountered an error. You should not
    /// modify the content of this task or start it yourself.
    
    // 真正的 URLLoading Sytem 的 task, 是存储在这个地方.
    // 同样的一个 URL, 只会创建一个 URLSessionDataTask, 如果之后使用同样的 URL 进行下载, 只是将回调进行了存储.
    public let task: URLSessionDataTask
    
    // 不同的下载任务, 是同样的拦截, 但是会是不同的回调.
    // 将这些逻辑, 是通过 callbacksStore 进行了保存.
    private var callbacksStore = [CancelToken: TaskCallback]()

    var callbacks: [SessionDataTask.TaskCallback] {
        lock.lock()
        defer { lock.unlock() }
        return Array(callbacksStore.values)
    }

    private var currentToken = 0
    private let lock = NSLock()

    let onTaskDone = Delegate<(Result<(Data, URLResponse?), KingfisherError>, [TaskCallback]), Void>()
    let onCallbackCancelled = Delegate<(CancelToken, TaskCallback), Void>()

    var started = false
    var containsCallbacks: Bool {
        // We should be able to use `task.state != .running` to check it.
        // However, in some rare cases, cancelling the task does not change
        // task state to `.cancelling` immediately, but still in `.running`.
        // So we need to check callbacks count to for sure that it is safe to remove the
        // task in delegate.
        return !callbacks.isEmpty
    }

    init(task: URLSessionDataTask) {
        self.task = task
        self.originalURL = task.originalRequest?.url
        // 这才是, 下载的图片的真实原始数据.
        mutableData = Data()
    }

    func addCallback(_ callback: TaskCallback) -> CancelToken {
        lock.lock()
        defer { lock.unlock() }
        
        callbacksStore[currentToken] = callback
        defer { currentToken += 1 }
        return currentToken
    }

    func removeCallback(_ token: CancelToken) -> TaskCallback? {
        lock.lock()
        defer { lock.unlock() }
        
        if let callback = callbacksStore[token] {
            callbacksStore[token] = nil
            return callback
        }
        return nil
    }
    
    func removeAllCallbacks() -> Void {
        lock.lock()
        defer { lock.unlock() }
        callbacksStore.removeAll()
    }

    func resume() {
        guard !started else { return }
        started = true
        task.resume()
    }

    func cancel(token: CancelToken) {
        guard let callback = removeCallback(token) else {
            return
        }
        // 没一个下载请求取消的时候, 都会触发 onCallbackCancelled.
        // 在 URLSessionDelegate 里面, 需要知道每次的取消事件, 用来管理自身的状态. 
        onCallbackCancelled.call((token, callback))
    }

    func forceCancel() {
        for token in callbacksStore.keys {
            cancel(token: token)
        }
    }

    func didReceiveData(_ data: Data) {
        mutableData.append(data)
    }
}
