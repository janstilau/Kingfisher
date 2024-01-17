
import Cocoa
import Kingfisher

class GIFHeavyViewController: NSViewController {
    @IBOutlet weak var stackView: NSStackView!
    
    let imageViews = [
        AnimatedImageView(),
        AnimatedImageView(),
        AnimatedImageView(),
        AnimatedImageView(),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF/GifHeavy.gif")
        
        for imageView in imageViews {
            stackView.addArrangedSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            imageView.imageScaling = .scaleProportionallyDown
        }
        stackView.layoutSubtreeIfNeeded()
        for imageView in imageViews {
            imageView.kf.setImage(with: url)
        }
    }
}
