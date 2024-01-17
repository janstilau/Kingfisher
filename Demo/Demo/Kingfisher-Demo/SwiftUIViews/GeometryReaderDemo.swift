
import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct GeometryReaderDemo: View {
    var body: some View {
        GeometryReader { geo in
            KFImage(
                ImageLoader.sampleImageURLs.first
            )
                .placeholder { ProgressView() }
                .forceRefresh()
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width)
        }
    }
}

@available(iOS 14.0, *)
struct GeometryReaderDemo_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReaderDemo()
    }
}
