
import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImageView: UIImageView!
    
    #if os(tvOS)
    override func awakeFromNib() {
        super.awakeFromNib()

        cellImageView.adjustsImageWhenAncestorFocused = true
        cellImageView.clipsToBounds = false
    }
    #endif
}
