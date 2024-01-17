
import AppKit
import Kingfisher

class ViewController: NSViewController {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Kingfisher"
    }

    @IBAction func clearCachePressed(sender: AnyObject) {
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
    }
    
    @IBAction func reloadPressed(sender: AnyObject) {
        collectionView.reloadData()
    }
}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cell"), for: indexPath)
        
        let url = URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-\(indexPath.item + 1).jpg")!
        
        item.imageView?.kf.indicatorType = .activity
        KF.url(url)
            .roundCorner(radius: .point(20))
            .onProgress { receivedSize, totalSize in print("\(indexPath.item + 1): \(receivedSize)/\(totalSize)") }
            .onSuccess { print($0) }
            .set(to: item.imageView!)
        
        // Set imageView's `animates` to true if you are loading a GIF.
        // item.imageView?.animates = true
        return item
    }
}
