
import UIKit
import AVKit
import Kingfisher

class AVAssetImageGeneratorViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let provider = AVAssetImageDataProvider(
            assetURL: URL(string: "https://github.com/onevcat/sample-files/raw/main/video/mp4/astronaut_flying_fantasy.mp4")!,
            seconds: 6.0
        )
        KF.dataProvider(provider).set(to: imageView)
    }
}
