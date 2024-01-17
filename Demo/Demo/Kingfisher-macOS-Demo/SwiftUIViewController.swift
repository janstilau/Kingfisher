
import SwiftUI
import Kingfisher

@available(macOS 11, *)
class SwiftUIViewController: NSHostingController<MainView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: MainView())
    }
}

@available(macOS 11, *)
struct MainView: View {
    @State private var index = 1
    
    static let gifImageURLs: [URL] = {
        let prefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF"
        return (1...3).map { URL(string: "\(prefix)/\($0).gif")! }
    }()
        
    var url: URL {
        MainView.gifImageURLs[index - 1]
    }
    
    var body: some View {
        VStack {
            KFAnimatedImage(url)
                .configure { view in
                    view.framePreloadCount = 3
                }
                .cacheOriginalImage()
                .onSuccess { r in
                    print("suc: \(r)")
                }
                .onFailure { e in
                    print("err: \(e)")
                }
                .placeholder { p in
                    ProgressView(p)
                }
                .fade(duration: 1)
                .forceTransition()
                .aspectRatio(contentMode: .fill)
                .frame(width: 300, height: 300)
                .cornerRadius(20)
                .shadow(radius: 5)
                .frame(width: 320, height: 320)

            Button(action: {
                self.index = (self.index % 3) + 1
            }) { Text("Next Image") }
        }
    }
}
