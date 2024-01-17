
#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImage {
    public class Context<HoldingView: KFImageHoldingView> {
        let source: Source?
        var options = KingfisherParsedOptionsInfo(
            KingfisherManager.shared.defaultOptions + [.loadDiskFileSynchronously]
        )

        var configurations: [(HoldingView) -> HoldingView] = []
        var renderConfigurations: [(HoldingView.RenderingView) -> Void] = []
        var contentConfiguration: ((HoldingView) -> AnyView)? = nil
        
        var cancelOnDisappear: Bool = false
        var placeholder: ((Progress) -> AnyView)? = nil

        let onFailureDelegate = Delegate<KingfisherError, Void>()
        let onSuccessDelegate = Delegate<RetrieveImageResult, Void>()
        let onProgressDelegate = Delegate<(Int64, Int64), Void>()
        
        var startLoadingBeforeViewAppear: Bool = false
        
        init(source: Source?) {
            self.source = source
        }
        
        func shouldApplyFade(cacheType: CacheType) -> Bool {
            options.forceTransition || cacheType == .none
        }

        func fadeTransitionDuration(cacheType: CacheType) -> TimeInterval? {
            shouldApplyFade(cacheType: cacheType)
            ? options.transition.fadeDuration
                : nil
        }
    }
}

extension ImageTransition {
    // Only for fade effect in SwiftUI.
    fileprivate var fadeDuration: TimeInterval? {
        switch self {
        case .fade(let duration):
            return duration
        default:
            return nil
        }
    }
}


@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImage.Context: Hashable {
    public static func == (lhs: KFImage.Context<HoldingView>, rhs: KFImage.Context<HoldingView>) -> Bool {
        lhs.source == rhs.source &&
        lhs.options.processor.identifier == rhs.options.processor.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(options.processor.identifier)
    }
}

#if !os(watchOS)
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFAnimatedImage {
    public typealias Context = KFImage.Context
    typealias ImageBinder = KFImage.ImageBinder
}
#endif

#endif
