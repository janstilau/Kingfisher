
import UIKit
import Kingfisher

private let reuseIdentifier = "HighResolution"

class HighResolutionCollectionViewController: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "High Resolution"
        setupOperationNavigationBar()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageLoader.highResolutionImageURLs.count * 30
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        (cell as! ImageCollectionViewCell).cellImageView.kf.cancelDownloadTask()
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath)
    {
        let imageView = (cell as! ImageCollectionViewCell).cellImageView!
        let url = ImageLoader.highResolutionImageURLs[indexPath.row % ImageLoader.highResolutionImageURLs.count]
        // Use different cache key to prevent reuse the same image. It is just for
        // this demo. Normally you can just use the URL to set image.

        // This should crash most devices due to memory pressure.
        // let resource = KF.ImageResource(downloadURL: url, cacheKey: "\(url.absoluteString)-\(indexPath.row)")
        // imageView.kf.setImage(with: resource)

        // This would survive on even the lowest spec devices!
        KF.url(url, cacheKey: "\(url.absoluteString)-\(indexPath.row)")
            .downsampling(size: CGSize(width: 250, height: 250))
            .cacheOriginalImage()
            .set(to: imageView)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImage" {
            let vc = segue.destination as! DetailImageViewController
            let index = collectionView.indexPathsForSelectedItems![0].row
            vc.imageURL =  ImageLoader.highResolutionImageURLs[index % ImageLoader.highResolutionImageURLs.count]
        }
    }
}
