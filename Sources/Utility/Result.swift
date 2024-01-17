
import Foundation

// These helper methods are not public since we do not want them to be exposed or cause any conflicting.
// However, they are just wrapper of `ResultUtil` static methods.
extension Result where Failure: Error {

    /// Evaluates the given transform closures to create a single output value.
    ///
    /// - Parameters:
    ///   - onSuccess: A closure that transforms the success value.
    ///   - onFailure: A closure that transforms the error value.
    /// - Returns: A single `Output` value.
    func match<Output>(
        onSuccess: (Success) -> Output,
        onFailure: (Failure) -> Output) -> Output
    {
        switch self {
        case let .success(value):
            return onSuccess(value)
        case let .failure(error):
            return onFailure(error)
        }
    }
}
