
import Kingfisher
import SwiftUI

@available(iOS 14.0, *)
struct SingleViewDemo : View {

    @State private var index = 1
    @State private var blackWhite = false
    @State private var forceTransition = true

    var url: URL {
        URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher-\(self.index).jpg")!
    }

    var body: some View {
        VStack {
            KFImage(url)
                .cacheOriginalImage()
                .setProcessor(blackWhite ? BlackWhiteProcessor() : DefaultImageProcessor())
                .onSuccess { r in
                    print("suc: \(r)")
                }
                .onFailure { e in
                    print("err: \(e)")
                }
                .placeholder { progress in
                    ProgressView(progress).frame(width: 100, height: 100)
                        .border(Color.blue)
                }
                .fade(duration: index == 1 ? 0 : 1) // Do not animate for the first image. Otherwise it causes an unwanted animation when the page is shown.
                .forceTransition(forceTransition)
                .resizable()
                .frame(width: 300, height: 300)
                .cornerRadius(20)
                .border(Color.red)
                .shadow(radius: 5)
                .frame(width: 320, height: 320)

            Button(action: {
                self.index = (self.index % 10) + 1
            }) { Text("Next Image") }
            Button(action: {
                self.blackWhite.toggle()
            }) { Text("Black & White") }
            Toggle("Force Transition?", isOn: $forceTransition)
                .frame(width: 300)

        }.navigationBarTitle(Text("Basic Image"), displayMode: .inline)
    }
}

@available(iOS 14.0, *)
struct SingleViewDemo_Previews : PreviewProvider {
    static var previews: some View {
        SingleViewDemo()
    }
}
