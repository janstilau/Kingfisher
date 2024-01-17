
import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct Issue1998View: View {
    var body: some View {
        Text("This is a test case for #1988")
        
        List {
            ForEach(1...100, id: \.self) { idx in
                KFImage(ImageLoader.sampleImageURLs.first)
                    .startLoadingBeforeViewAppear()
                    .resizable()
                    .frame(width: 48, height: 48)
            }
        }
    }
}

@available(iOS 14.0, *)
struct SingleListDemo_Previews: PreviewProvider {
    static var previews: some View {
        Issue1998View()
    }
}
