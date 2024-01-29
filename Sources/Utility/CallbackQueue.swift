
import Foundation

// Callback, 更多的是回调的含义.
// 但是在整个的图像处理的过程里面, 会有 Execution 的概念.
public typealias ExecutionQueue = CallbackQueue

/// Represents callback queue behaviors when an calling of closure be dispatched.
///
/// - asyncMain: Dispatch the calling to `DispatchQueue.main` with an `async` behavior.
/// - currentMainOrAsync: Dispatch the calling to `DispatchQueue.main` with an `async` behavior if current queue is not
///                       `.main`. Otherwise, call the closure immediately in current main queue.
/// - untouch: Do not change the calling queue for closure.
/// - dispatch: Dispatches to a specified `DispatchQueue`.

// 这里控制的是, 如何触发回调.
public enum CallbackQueue {
    /// Dispatch the calling to `DispatchQueue.main` with an `async` behavior.
    // async  到 main quque.
    case mainAsync
    /// Dispatch the calling to `DispatchQueue.main` with an `async` behavior if current queue is not
    /// `.main`. Otherwise, call the closure immediately in current main queue.
    // async 到 main queue. 或者在 mainqueue 直接触发.
    case mainCurrentOrAsync
    /// Do not change the calling queue for closure.
    // 不进行线程的调度, 直接原来在哪个队列, 就在哪个队列里面. 
    case untouch
    /// Dispatches to a specified `DispatchQueue`.
    // 使用指定的 Queue.
    case dispatch(DispatchQueue)
    
    // 最终其实还是使用 DiapatchQueue 进行调度.
    // 各种 Case 的设计, 使得
    public func execute(_ block: @escaping () -> Void) {
        switch self {
        case .mainAsync:
            DispatchQueue.main.async { block() }
        case .mainCurrentOrAsync:
            DispatchQueue.main.safeAsync { block() }
        case .untouch:
            block()
        case .dispatch(let queue):
            queue.async { block() }
        }
    }

    var queue: DispatchQueue {
        switch self {
        case .mainAsync: return .main
        case .mainCurrentOrAsync: return .main
        case .untouch: return OperationQueue.current?.underlyingQueue ?? .main
        case .dispatch(let queue): return queue
        }
    }
}

// 这是一个非常非常常用的一个扩展, 在很多的地方, 都会使用的到. 
extension DispatchQueue {
    // This method will dispatch the `block` to self.
    // If `self` is the main queue, and current thread is main thread, the block
    // will be invoked immediately instead of being dispatched.
    // 这里的命名不好, 应该有 Main 相关的命名才对. 
    func safeAsync(_ block: @escaping () -> Void) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}
