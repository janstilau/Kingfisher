
import Foundation

/// A class that keeps a weakly reference for `self` when implementing `onXXX` behaviors.
/// Instead of remembering to keep `self` as weak in a stored closure:
///
/// ```swift
/// // MyClass.swift
/// var onDone: (() -> Void)?
/// func done() {
///     onDone?()
/// }
///
/// // ViewController.swift
/// var obj: MyClass?
///
/// func doSomething() {
///     obj = MyClass()
///     obj!.onDone = { [weak self] in
///         self?.reportDone()
///     }
/// }
/// ```
///
/// You can create a `Delegate` and observe on `self`. Now, there is no retain cycle inside:
///
/// ```swift
/// // MyClass.swift
/// let onDone = Delegate<(), Void>()
/// func done() {
///     onDone.call()
/// }
///
/// // ViewController.swift
/// var obj: MyClass?
///
/// func doSomething() {
///     obj = MyClass()
///     obj!.onDone.delegate(on: self) { (self, _)
///         // `self` here is shadowed and does not keep a strong ref.
///         // So you can release both `MyClass` instance and `ViewController` instance.
///         self.reportDone()
///     }
/// }
/// ```

/*
 这里使用了泛型.
 其实这个类的主要功能, 其实就是存储一个 block.
 
 目前来说, 使用 Block 来进行操作, 是更加方便的方式.
 这种对象, 提供比较好用的方法, 进行扩展, 但是核心的存储对象就是一个 block.
 */

// Delegate 是一个盒子, 它是需要专门配置的.
// 可以看到, 就是 delegate 方法, block 是一个 private 的属性, 需要主动调用 delegate 才能够将 block 填入值去.
// 使用这种, 避免了 Init 的时候, 把各种 Block 设置为 Optional 的, 但是还是需要主动调用进行里面的 Block 的设置. 
public class Delegate<Input, Output> {
    public init() {}

    private var block: ((Input) -> Output?)?
    
    public func delegate<T: AnyObject>(on target: T, block: ((T, Input) -> Output)?) {
        self.block = { [weak target] input in
            guard let target = target else { return nil }
            return block?(target, input)
        }
    }

    public func call(_ input: Input) -> Output? {
        return block?(input)
    }

    // 一个可调用对象的适配.
    public func callAsFunction(_ input: Input) -> Output? {
        return call(input)
    }
}

extension Delegate where Input == Void {
    public func call() -> Output? {
        return call(())
    }

    public func callAsFunction() -> Output? {
        return call()
    }
}

extension Delegate where Input == Void, Output: OptionalProtocol {
    public func call() -> Output {
        return call(())
    }

    public func callAsFunction() -> Output {
        return call()
    }
}

extension Delegate where Output: OptionalProtocol {
    public func call(_ input: Input) -> Output {
        if let result = block?(input) {
            return result
        } else {
            return Output._createNil
        }
    }

    public func callAsFunction(_ input: Input) -> Output {
        return call(input)
    }
}

public protocol OptionalProtocol {
    static var _createNil: Self { get }
}
extension Optional : OptionalProtocol {
    public static var _createNil: Optional<Wrapped> {
         return nil
    }
}
