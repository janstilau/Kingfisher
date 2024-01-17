
import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct LazyVStackDemo: View {
    @State private var singleImage = false
    
    var body: some View {
        ScrollView {
            // Checking for #1839
            Toggle("Single Image", isOn: $singleImage).padding()
            LazyVStack {
                ForEach(1..<700) { i in
                    if singleImage {
                        KFImage.url(ImageLoader.roseImage(index: 1))
                    } else {
                        ImageCell(index: i).frame(width: 300, height: 300)
                    }
                }
            }
        }.navigationBarTitle(Text("Lazy Stack"), displayMode: .inline)
    }
}

@available(iOS 14.0, *)
struct LazyVStackDemo_Previews: PreviewProvider {
    static var previews: some View {
        LazyVStackDemo()
    }
}
