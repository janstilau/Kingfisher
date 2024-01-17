
#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct KFImage: KFImageProtocol {
    public var context: Context<Image>
    public init(context: Context<Image>) {
        self.context = context
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Image: KFImageHoldingView {
    public typealias RenderingView = Image
    public static func created(from image: KFCrossPlatformImage?, context: KFImage.Context<Self>) -> Image {
        Image(crossPlatformImage: image)
    }
}

// MARK: - Image compatibility.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImage {

    public func resizable(
        capInsets: EdgeInsets = EdgeInsets(),
        resizingMode: Image.ResizingMode = .stretch) -> KFImage
    {
        configure { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }

    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> KFImage {
        configure { $0.renderingMode(renderingMode) }
    }

    public func interpolation(_ interpolation: Image.Interpolation) -> KFImage {
        configure { $0.interpolation(interpolation) }
    }

    public func antialiased(_ isAntialiased: Bool) -> KFImage {
        configure { $0.antialiased(isAntialiased) }
    }
    
    /// Starts the loading process of `self` immediately.
    ///
    /// By default, a `KFImage` will not load its source until the `onAppear` is called. This is a lazily loading
    /// behavior and provides better performance. However, when you refresh the view, the lazy loading also causes a
    /// flickering since the loading does not happen immediately. Call this method if you want to start the load at once
    /// could help avoiding the flickering, with some performance trade-off.
    ///
    /// - Deprecated: This is not necessary anymore since `@StateObject` is used for holding the image data.
    /// It does nothing now and please just remove it.
    ///
    /// - Returns: The `Self` value with changes applied.
    @available(*, deprecated, message: "This is not necessary anymore since `@StateObject` is used. It does nothing now and please just remove it.")
    public func loadImmediately(_ start: Bool = true) -> KFImage {
        return self
    }
}

#if DEBUG
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct KFImage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            KFImage.url(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png")!)
                .onSuccess { r in
                    print(r)
                }
                .placeholder { p in
                    ProgressView(p)
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
        }
    }
}
#endif
#endif
