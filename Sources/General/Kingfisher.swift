
import Foundation
import ImageIO

#if os(macOS)
import AppKit
public typealias KFCrossPlatformImage = NSImage
public typealias KFCrossPlatformView = NSView
public typealias KFCrossPlatformColor = NSColor
public typealias KFCrossPlatformImageView = NSImageView
public typealias KFCrossPlatformButton = NSButton
#else
import UIKit
public typealias KFCrossPlatformImage = UIImage
public typealias KFCrossPlatformColor = UIColor
#if !os(watchOS)
public typealias KFCrossPlatformImageView = UIImageView
public typealias KFCrossPlatformView = UIView
public typealias KFCrossPlatformButton = UIButton
#if canImport(TVUIKit)
import TVUIKit
#endif
#if canImport(CarPlay) && !targetEnvironment(macCatalyst)
import CarPlay
#endif
#else
import WatchKit
#endif
#endif

/// Wrapper for Kingfisher compatible types. This type provides an extension point for
/// convenience methods in Kingfisher.
public struct KingfisherWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/// Represents an object type that is compatible with Kingfisher. You can use `kf` property to get a
/// value in the namespace of Kingfisher.
public protocol KingfisherCompatible: AnyObject { }

/// Represents a value type that is compatible with Kingfisher. You can use `kf` property to get a
/// value in the namespace of Kingfisher.
public protocol KingfisherCompatibleValue {}

extension KingfisherCompatible {
    /// Gets a namespace holder for Kingfisher compatible types.
    public var kf: KingfisherWrapper<Self> {
        get { return KingfisherWrapper(self) }
        set { }
    }
}

extension KingfisherCompatibleValue {
    /// Gets a namespace holder for Kingfisher compatible types.
    public var kf: KingfisherWrapper<Self> {
        get { return KingfisherWrapper(self) }
        set { }
    }
}

extension KFCrossPlatformImage: KingfisherCompatible { }
#if !os(watchOS)
extension KFCrossPlatformImageView: KingfisherCompatible { }
extension KFCrossPlatformButton: KingfisherCompatible { }
extension NSTextAttachment: KingfisherCompatible { }
#else
extension WKInterfaceImage: KingfisherCompatible { }
#endif

#if os(tvOS) && canImport(TVUIKit)
@available(tvOS 12.0, *)
extension TVMonogramView: KingfisherCompatible { }
#endif

#if canImport(CarPlay) && !targetEnvironment(macCatalyst)
@available(iOS 14.0, *)
extension CPListItem: KingfisherCompatible { }
#endif
