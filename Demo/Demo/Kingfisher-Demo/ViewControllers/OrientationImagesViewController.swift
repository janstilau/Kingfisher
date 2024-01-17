
import UIKit
import Kingfisher

class OrientationImagesViewController: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "EXIF"
        setupOperationNavigationBar()
    }
}

extension OrientationImagesViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageLoader.orientationImageURLs.count
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath)
    {
        // This will cancel all unfinished downloading task when the cell disappearing.
        (cell as! ImageCollectionViewCell).cellImageView.kf.cancelDownloadTask()
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath)
    {
        let imageView = (cell as! ImageCollectionViewCell).cellImageView!
        let url = ImageLoader.orientationImageURLs[indexPath.row]
        KF.url(url)
            .fade(duration: 1)
            .backgroundDecode([0, 1].randomElement() == 0)
            .loadDiskFileSynchronously()
            .onProgress { (received, total) in print("\(indexPath.row + 1): \(received)/\(total)") }
            .onSuccess { print($0) }
            .onFailure { err in print("Error: \(err)") }
            .set(to: imageView)
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "collectionViewCell",
            for: indexPath) as! ImageCollectionViewCell
        cell.cellImageView.kf.indicatorType = .activity
        return cell
    }
}
