
import UIKit
import Kingfisher

// Cell with an image view (loading by Kingfisher) with fix width and dynamic height which keeps the image with aspect ratio.
class AutoSizingTableViewCell: UITableViewCell {
    
    static let p = ResizingImageProcessor(referenceSize: .init(width: 200, height: CGFloat.infinity), mode: .aspectFit)
    
    @IBOutlet weak var leadingImageView: UIImageView!
    @IBOutlet weak var sizeLabel: UILabel!
    
    var updateLayout: (() -> Void)?
    
    func set(with url: URL) {
        leadingImageView.kf.setImage(with: url, options: [.processor(AutoSizingTableViewCell.p), .transition(.fade(1))]) { r in
            if case .success(let value) = r {
                self.sizeLabel.text = "\(value.image.size.width) x \(value.image.size.height)"
                self.updateLayout?()
            } else {
                self.sizeLabel.text = ""
            }
        }
    }
}

class AutoSizingTableViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var data: [Int] = Array(1..<700)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 150
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.setAnimationsEnabled(false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.setAnimationsEnabled(true)
    }
}

extension AutoSizingTableViewController: UITableViewDataSource {
    private func updateLayout() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AutoSizingTableViewCell", for: indexPath) as! AutoSizingTableViewCell
        cell.set(with: ImageLoader.roseImage(index: data[indexPath.row]))
        cell.updateLayout = { [weak self] in
            self?.updateLayout()
        }
        return cell
    }
    
    
}
