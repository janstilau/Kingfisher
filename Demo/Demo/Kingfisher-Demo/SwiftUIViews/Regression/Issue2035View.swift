
import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct Issue2035View: View {
    var body: some View {
        KFImage(nil)
            .startLoadingBeforeViewAppear()
            .onSuccess { _ in
                print("Done")
            }
            .onFailure { err in
                print(err)
            }
    }
}

@available(iOS 14.0, *)
struct Issue2035View_Previews: PreviewProvider {
    static var previews: some View {
        Issue2035View()
    }
}
