
import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct AnimatedImageDemo: View {
    
    @State private var index = 1
        
    var url: URL {
        ImageLoader.gifImageURLs[index - 1]
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
        }.navigationBarTitle(Text("Basic Image"), displayMode: .inline)
    }
    
}

@available(iOS 14.0, *)
struct AnimatedImageDemo_Previews: PreviewProvider {
    
    static var previews: some View {
        AnimatedImageDemo()
    }
    
}

