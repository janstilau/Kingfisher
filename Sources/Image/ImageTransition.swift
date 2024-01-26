
import Foundation
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

/// Transition effect which will be used when an image downloaded and set by `UIImageView`
/// extension API in Kingfisher. You can assign an enum value with transition duration as
/// an item in `KingfisherOptionsInfo` to enable the animation transition.
///
/// Apple's UIViewAnimationOptions is used under the hood.
/// For custom transition, you should specified your own transition options, animations and
/// completion handler as well.
///
/// - none: No animation transition.
/// - fade: Fade in the loaded image in a given duration.
/// - flipFromLeft: Flip from left transition.
/// - flipFromRight: Flip from right transition.
/// - flipFromTop: Flip from top transition.
/// - flipFromBottom: Flip from bottom transition.
/// - custom: Custom transition.

/// 在由 Kingfisher 的 `UIImageView` 扩展 API 下载并设置的图像时使用的过渡效果。你可以在 `KingfisherOptionsInfo` 中分配一个带有过渡持续时间的枚举值作为动画过渡的选项之一。
///
/// 在底层使用了 Apple 的 UIViewAnimationOptions。
/// 对于自定义过渡，你应该指定自己的过渡选项、动画和完成处理程序。
///
/// - none: 无动画过渡。
/// - fade: 在给定的持续时间内淡入加载的图像。
/// - flipFromLeft: 从左侧翻转过渡。
/// - flipFromRight: 从右侧翻转过渡。
/// - flipFromTop: 从顶部翻转过渡。
/// - flipFromBottom: 从底部翻转过渡。
/// - custom: 自定义过渡。

// 使用 Enum 当做存储器. 如果不是 Node, 每种 case, 其实都会有 duration 的存储.
public enum ImageTransition {
    /// No animation transition.
    case none
    /// Fade in the loaded image in a given duration.
    case fade(TimeInterval)
    /// Flip from left transition.
    case flipFromLeft(TimeInterval)
    /// Flip from right transition.
    case flipFromRight(TimeInterval)
    /// Flip from top transition.
    case flipFromTop(TimeInterval)
    /// Flip from bottom transition.
    case flipFromBottom(TimeInterval)

    /// Custom transition defined by a general animation block.
    ///    - duration: The time duration of this custom transition.
    ///    - options: `UIView.AnimationOptions` should be used in the transition.
    ///    - animations: The animation block will be applied when setting image.
    ///    - completion: A block called when the transition animation finishes.
    case custom(duration: TimeInterval,
                 options: UIView.AnimationOptions,
              animations: ((UIImageView, UIImage) -> Void)?,
              completion: ((Bool) -> Void)?)
    
    
    // enum 的常态. 在各种方法里面, 基本上都是 switch self 做处理.
    var duration: TimeInterval {
        switch self {
        case .none:                          return 0
        case .fade(let duration):            return duration
            
        case .flipFromLeft(let duration):    return duration
        case .flipFromRight(let duration):   return duration
        case .flipFromTop(let duration):     return duration
        case .flipFromBottom(let duration):  return duration
            
        case .custom(let duration, _, _, _): return duration
        }
    }
    
    var animationOptions: UIView.AnimationOptions {
        switch self {
        case .none:                         return []
        case .fade:                         return .transitionCrossDissolve
            
        case .flipFromLeft:                 return .transitionFlipFromLeft
        case .flipFromRight:                return .transitionFlipFromRight
        case .flipFromTop:                  return .transitionFlipFromTop
        case .flipFromBottom:               return .transitionFlipFromBottom
            
        case .custom(_, let options, _, _): return options
        }
    }
    
    // 动作这件事. 如果是系统的 option, 就是 { $0.image = $1 }
    var animations: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .custom(_, _, let animations, _): return animations
        default: return { $0.image = $1 }
        }
    }
    
    var completion: ((Bool) -> Void)? {
        switch self {
        case .custom(_, _, _, let completion): return completion
        default: return nil
        }
    }
}
#else
// Just a placeholder for compiling on macOS.
public enum ImageTransition {
    case none
    /// This is a placeholder on macOS now. It is for SwiftUI (KFImage) to identify the fade option only.
    case fade(TimeInterval)
}
#endif
