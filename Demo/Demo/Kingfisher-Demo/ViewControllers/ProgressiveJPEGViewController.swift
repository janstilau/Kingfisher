
import UIKit
import Kingfisher

class ProgressiveJPEGViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    
    private var isBlur = true
    private var isFastestScan = true
    
    private let processor = RoundCornerImageProcessor(cornerRadius: 30)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Progressive JPEG"
        setupOperationNavigationBar()
        loadImage()
    }
    
    private func loadImage() {
        progressLabel.text = "- / -"
        
        let progressive = ImageProgressive(
            isBlur: isBlur,
            isFastestScan: isFastestScan,
            scanInterval: 0.1
        )

        KF.url(ImageLoader.progressiveImageURL)
            .loadDiskFileSynchronously()
            .progressiveJPEG(progressive)
            .roundCorner(radius: .point(30))
            .onProgress { receivedSize, totalSize in
                print("\(receivedSize)/\(totalSize)")
                self.progressLabel.text = "\(receivedSize) / \(totalSize)"
            }
            .onSuccess { result in
                print(result)
                print("Finished")
            }
            .onFailure { error in
                print(error)
                self.progressLabel.text = error.localizedDescription
            }
            .set(to: imageView)
    }
    
    override func alertPopup(_ sender: Any) -> UIAlertController {
        let alert = super.alertPopup(sender)
        
        func reloadImage() {
            // Cancel
            imageView.kf.cancelDownloadTask()
            // Clean cache
            KingfisherManager.shared.cache.removeImage(
                forKey: ImageLoader.progressiveImageURL.cacheKey,
                processorIdentifier: self.processor.identifier,
                callbackQueue: .mainAsync,
                completionHandler: {
                    self.loadImage()
                }
            )
        }
        
        do {
            let title = isBlur ? "Disable Blur" : "Enable Blur"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.isBlur.toggle()
                reloadImage()
            })
        }
        
        do {
            let title = isFastestScan ? "Disable Fastest Scan" : "Enable Fastest Scan"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.isFastestScan.toggle()
                reloadImage()
            })
        }
        return alert
    }
}
