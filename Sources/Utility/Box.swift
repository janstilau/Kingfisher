
import Foundation

// 这是一个引用值.
// 这个就是为了将, 任何的, 非引用值的数据, 也都可以进行存储. 
class Box<T> {
    var value: T
    
    init(_ value: T) {
        self.value = value
    }
}
