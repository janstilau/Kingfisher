
import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct SizingAnimationDemo: View {
    @State var imageSize: CGFloat = 250
    @State var isPlaying = false

    var body: some View {
        VStack {
            KFImage(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher-1.jpg")!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .frame(width: 350, height: 350)
            Button(action: {
                playButtonAction()
            }) {
                Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 60))
            }
        }

    }
    func playButtonAction() {
        withAnimation(Animation.spring(response: 0.45, dampingFraction: 0.475, blendDuration: 0)) {
            if self.imageSize == 250 {
                self.imageSize = 350
            } else {
                self.imageSize = 250
            }
            self.isPlaying.toggle()
        }
    }
}

@available(iOS 14.0, *)
struct SizingAnimationDemo_Previews: PreviewProvider {
    static var previews: some View {
        SizingAnimationDemo()
    }
}
