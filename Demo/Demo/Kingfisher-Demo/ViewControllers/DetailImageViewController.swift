
import UIKit

class DetailImageViewController: UIViewController {

    var imageURL: URL!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        imageView.kf.setImage(with: imageURL, options: [.memoryCacheExpiration(.expired)]) { result in
            guard let image = try? result.get().image else {
                return
            }
            let scrollViewFrame = self.scrollView.frame
            let scaleWidth = scrollViewFrame.size.width / image.size.width
            let scaleHeight = scrollViewFrame.size.height / image.size.height
            let minScale = min(scaleWidth, scaleHeight)
            self.scrollView.minimumZoomScale = minScale
            DispatchQueue.main.async {
                self.scrollView.zoomScale = minScale
            }
            
            self.infoLabel.text = "\(image.size)"
        }
    }
}

extension DetailImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
