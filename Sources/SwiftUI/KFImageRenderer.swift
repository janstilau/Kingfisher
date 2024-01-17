
#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

/// A Kingfisher compatible SwiftUI `View` to load an image from a `Source`.
/// Declaring a `KFImage` in a `View`'s body to trigger loading from the given `Source`.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct KFImageRenderer<HoldingView> : View where HoldingView: KFImageHoldingView {
    
    @StateObject var binder: KFImage.ImageBinder = .init()
    let context: KFImage.Context<HoldingView>
    
    var body: some View {
        if context.startLoadingBeforeViewAppear && !binder.loadingOrSucceeded && !binder.animating {
            binder.markLoading()
            DispatchQueue.main.async { binder.start(context: context) }
        }
        
        return ZStack {
            renderedImage().opacity(binder.loaded ? 1.0 : 0.0)
            if binder.loadedImage == nil {
                ZStack {
                    if let placeholder = context.placeholder {
                        placeholder(binder.progress)
                    } else {
                        Color.clear
                    }
                }
                .onAppear { [weak binder = self.binder] in
                    guard let binder = binder else {
                        return
                    }
                    if !binder.loadingOrSucceeded {
                        binder.start(context: context)
                    }
                }
                .onDisappear { [weak binder = self.binder] in
                    guard let binder = binder else {
                        return
                    }
                    if context.cancelOnDisappear {
                        binder.cancel()
                    }
                }
            }
        }
        // Workaround for https://github.com/onevcat/Kingfisher/issues/1988
        // on iOS 16 there seems to be a bug that when in a List, the `onAppear` of the `ZStack` above in the
        // `binder.loadedImage == nil` not get called. Adding this empty `onAppear` fixes it and the life cycle can
        // work again.
        //
        // There is another "fix": adding an `else` clause and put a `Color.clear` there. But I believe this `onAppear`
        // should work better.
        //
        // It should be a bug in iOS 16, I guess it is some kinds of over-optimization in list cell loading caused it.
        .onAppear()
    }
    
    @ViewBuilder
    private func renderedImage() -> some View {
        let configuredImage = context.configurations
            .reduce(HoldingView.created(from: binder.loadedImage, context: context)) {
                current, config in config(current)
            }
        if let contentConfiguration = context.contentConfiguration {
            contentConfiguration(configuredImage)
        } else {
            configuredImage
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Image {
    // Creates an Image with either UIImage or NSImage.
    init(crossPlatformImage: KFCrossPlatformImage?) {
        #if canImport(UIKit)
        self.init(uiImage: crossPlatformImage ?? KFCrossPlatformImage())
        #elseif canImport(AppKit)
        self.init(nsImage: crossPlatformImage ?? KFCrossPlatformImage())
        #endif
    }
}

#if canImport(UIKit)
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension UIImage.Orientation {
    func toSwiftUI() -> Image.Orientation {
        switch self {
        case .down: return .down
        case .up: return .up
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
#endif
#endif
