
import UIKit
import Kingfisher

private let reuseIdentifier = "ProcessorCell"

class ProcessorCollectionViewController: UICollectionViewController {

    var currentProcessor: ImageProcessor = DefaultImageProcessor.default {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var processors: [(ImageProcessor, String)] = [
        (DefaultImageProcessor.default, "Default"),
        (ResizingImageProcessor(referenceSize: CGSize(width: 50, height: 50)), "Resizing"),
        (RoundCornerImageProcessor(radius: .point(20)), "Round Corner"),
        (RoundCornerImageProcessor(radius: .widthFraction(0.5), roundingCorners: [.topLeft, .bottomRight]), "Round Corner Partial"),
        (BorderImageProcessor(border: .init(color: .systemBlue, lineWidth: 8)), "Border"),
        (RoundCornerImageProcessor(radius: .widthFraction(0.2)) |> BorderImageProcessor(border: .init(color: UIColor.systemBlue.withAlphaComponent(0.7), lineWidth: 12, radius: .widthFraction(0.2))), "Round Border"),
        (BlendImageProcessor(blendMode: .lighten, alpha: 1.0, backgroundColor: .red), "Blend"),
        (BlurImageProcessor(blurRadius: 5), "Blur"),
        (OverlayImageProcessor(overlay: .red, fraction: 0.5), "Overlay"),
        (TintImageProcessor(tint: UIColor.red.withAlphaComponent(0.5)), "Tint"),
        (ColorControlsProcessor(brightness: 0.0, contrast: 1.1, saturation: 1.1, inputEV: 1.0), "Vibrancy"),
        (BlackWhiteProcessor(), "B&W"),
        (CroppingImageProcessor(size: CGSize(width: 100, height: 100)), "Cropping"),
        (DownsamplingImageProcessor(size: CGSize(width: 25, height: 25)), "Downsampling"),
        (BlurImageProcessor(blurRadius: 5) |> RoundCornerImageProcessor(cornerRadius: 20), "Blur + Round Corner")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Processor"
        setupOperationNavigationBar()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageLoader.sampleImageURLs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        let url = ImageLoader.sampleImageURLs[indexPath.row]

        KF.url(url)
            .setProcessor(currentProcessor)
            .serialize(as: .PNG)
            .onSuccess { print($0) }
            .onFailure { print($0) }
            .set(to: cell.cellImageView)

        return cell
    }
    
    override func alertPopup(_ sender: Any) -> UIAlertController {
        let alert = super.alertPopup(sender)
        alert.addAction(UIAlertAction(title: "Processor", style: .default, handler: { _ in
            let alert = UIAlertController(title: "Processor", message: nil, preferredStyle: .actionSheet)
            for item in self.processors {
                alert.addAction(UIAlertAction(title: item.1, style: .default) { _ in self.currentProcessor = item.0 })
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.present(alert, animated: true)
        }))
        return alert
    }
}
