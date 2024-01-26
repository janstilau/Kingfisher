
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// An `ImageModifier` can be used to change properties on an image between cache serialization and the actual use of
/// the image. The `modify(_:)` method will be called after the image retrieved from its source and before it returned
/// to the caller. This modified image is expected to be only used for rendering purpose, any changes applied by the
/// `ImageModifier` will not be serialized or cached.

/// `ImageModifier` 可用于在缓存序列化和实际使用图像之间更改图像的属性。
/// `modify(_:)` 方法将在从其源获取图像后并在将其返回给调用者之前调用。预期仅使用由 `ImageModifier` 应用于呈现的图像，
/// `ImageModifier` 应用的任何更改都不会被序列化或缓存。
public protocol ImageModifier {
    /// Modify an input `Image`.
    ///
    /// - parameter image:   Image which will be modified by `self`
    ///
    /// - returns: The modified image.
    ///
    /// - Note: The return value will be unmodified if modifying is not possible on
    ///         the current platform.
    /// - Note: Most modifiers support UIImage or NSImage, but not CGImage.
    /// 修改输入的 `Image`。
    ///
    /// - parameter image:   将由 `self` 修改的图像
    ///
    /// - returns: 修改后的图像。
    ///
    /// - Note: 如果在当前平台上无法修改，则返回值将保持不变。
    /// - Note: 大多数修改器支持 UIImage 或 NSImage，但不支持 CGImage。
    func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage
}

/// A wrapper for creating an `ImageModifier` easier.
/// This type conforms to `ImageModifier` and wraps an image modify block.
/// If the `block` throws an error, the original image will be used.
public struct AnyImageModifier: ImageModifier {

    /// A block which modifies images, or returns the original image
    /// if modification cannot be performed with an error.
    let block: (KFCrossPlatformImage) throws -> KFCrossPlatformImage

    /// Creates an `AnyImageModifier` with a given `modify` block.
    public init(modify: @escaping (KFCrossPlatformImage) throws -> KFCrossPlatformImage) {
        block = modify
    }

    /// Modify an input `Image`. See `ImageModifier` protocol for more.
    public func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        return (try? block(image)) ?? image
    }
}

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit

/// Modifier for setting the rendering mode of images.
public struct RenderingModeImageModifier: ImageModifier {

    /// The rendering mode to apply to the image.
    public let renderingMode: UIImage.RenderingMode

    /// Creates a `RenderingModeImageModifier`.
    ///
    /// - Parameter renderingMode: The rendering mode to apply to the image. Default is `.automatic`.
    public init(renderingMode: UIImage.RenderingMode = .automatic) {
        self.renderingMode = renderingMode
    }

    /// Modify an input `Image`. See `ImageModifier` protocol for more.
    public func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        return image.withRenderingMode(renderingMode)
    }
}

/// Modifier for setting the `flipsForRightToLeftLayoutDirection` property of images.
public struct FlipsForRightToLeftLayoutDirectionImageModifier: ImageModifier {

    /// Creates a `FlipsForRightToLeftLayoutDirectionImageModifier`.
    public init() {}

    /// Modify an input `Image`. See `ImageModifier` protocol for more.
    public func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        return image.imageFlippedForRightToLeftLayoutDirection()
    }
}

/// Modifier for setting the `alignmentRectInsets` property of images.
public struct AlignmentRectInsetsImageModifier: ImageModifier {

    /// The alignment insets to apply to the image
    public let alignmentInsets: UIEdgeInsets

    /// Creates an `AlignmentRectInsetsImageModifier`.
    public init(alignmentInsets: UIEdgeInsets) {
        self.alignmentInsets = alignmentInsets
    }

    /// Modify an input `Image`. See `ImageModifier` protocol for more.
    public func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        return image.withAlignmentRectInsets(alignmentInsets)
    }
}
#endif
