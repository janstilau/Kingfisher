
import Foundation

// 原来的方法, 实在是难以记忆, 这里使用更加 Swfit 的方式进行了包装.
// 这会是在 Get, Set 里面使用, 所以, 在真正使用的时候, 一定是 T 可以确定的.
// 这里的存储方式, 都是 retain, 是因为所有的数据, 都使用了 box 进行了存储. 
func getAssociatedObject<T>(_ object: Any, _ key: UnsafeRawPointer) -> T? {
    if #available(iOS 14, macOS 11, watchOS 7, tvOS 14, *) { // swift 5.3 fixed this issue (https://github.com/apple/swift/issues/46456)
        return objc_getAssociatedObject(object, key) as? T
    } else {
        return objc_getAssociatedObject(object, key) as AnyObject as? T
    }
}

func setRetainedAssociatedObject<T>(_ object: Any, _ key: UnsafeRawPointer, _ value: T) {
    objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}
