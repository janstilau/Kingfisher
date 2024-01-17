
import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct TransitionViewDemo: View {
    @State private var showDetails = false
    
    var body: some View {
        VStack {
            Button(showDetails ? "Hide" : "Show") {
                withAnimation {
                    showDetails.toggle()
                }
            }
            if showDetails {
                KFImage(ImageLoader.sampleImageURLs.first)
                    .transition(.slide)
            }
            Spacer()
        }.frame(height: 500)
    }
}

@available(iOS 14.0, *)
struct TransitionViewDemo_Previews: PreviewProvider {
    static var previews: some View {
        TransitionViewDemo()
    }
}
