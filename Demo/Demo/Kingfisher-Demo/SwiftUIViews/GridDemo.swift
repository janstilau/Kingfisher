
import SwiftUI

@available(iOS 14.0, *)
struct GridDemo: View {

    @State var columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(1..<700) { i in
                    ImageCell(index: i).frame(height: columns.count == 1 ? 300 : 150)
                }
            }
        }.navigationBarTitle(Text("Grid"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {

                    withAnimation(Animation.easeInOut(duration: 0.25)) {
                        self.columns = Array(repeating: .init(.flexible()), count: self.columns.count % 4 + 1)
                    }
                }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.title)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct GridDemo_Previews: PreviewProvider {
    static var previews: some View {
        GridDemo()
    }
}
