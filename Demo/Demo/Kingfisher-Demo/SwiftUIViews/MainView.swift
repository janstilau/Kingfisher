
import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct MainView: View {
    var body: some View {
        List {
            Section {
                Button(
                    action: {
                        KingfisherManager.shared.cache.clearMemoryCache()
                        KingfisherManager.shared.cache.clearDiskCache()
                    },
                    label: {
                        Text("Clear Cache").foregroundColor(.blue)
                    }
                )
            }
            
            Section(header: Text("Demo")) {
                NavigationLink(destination: SingleViewDemo()) { Text("Basic Image") }
                NavigationLink(destination: SizingAnimationDemo()) { Text("Sizing Toggle") }
                NavigationLink(destination: ListDemo()) { Text("List") }
                NavigationLink(destination: LazyVStackDemo()) { Text("Stack") }
                NavigationLink(destination: GridDemo()) { Text("Grid") }
                NavigationLink(destination: AnimatedImageDemo()) { Text("Animated Image") }
                NavigationLink(destination: GeometryReaderDemo()) { Text("Geometry Reader") }
                NavigationLink(destination: TransitionViewDemo()) { Text("Transition") }
            }
            
            Section(header: Text("Regression Cases")) {
                NavigationLink(destination: Issue1998View()) { Text("#1998") }
                NavigationLink(destination: Issue2035View()) { Text("#2035") }
            }
        }.navigationBarTitle(Text("SwiftUI Sample"))
    }
}

@available(iOS 14.0, *)
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
