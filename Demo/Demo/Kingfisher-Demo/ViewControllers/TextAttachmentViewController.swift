
import UIKit
import Kingfisher

class TextAttachmentViewController: UIViewController {
    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Text Attachment"
        setupOperationNavigationBar()

        loadAttributedText()
    }

    private func loadAttributedText() {
        let attributedText = NSMutableAttributedString(string: "Hello World")

        let textAttachment = NSTextAttachment()
        attributedText.replaceCharacters(in: NSRange(), with: NSAttributedString(attachment: textAttachment))
        label.attributedText = attributedText

        KF.url(URL(string: "https://onevcat.com/assets/images/avatar.jpg")!)
            .resizing(referenceSize: CGSize(width: 30, height: 30))
            .roundCorner(radius: .point(15))
            .set(to: textAttachment, attributedView: self.getLabel())
    }
    
    func getLabel() -> UILabel {
        return label
    }
}

extension TextAttachmentViewController: MainDataViewReloadable {
    func reload() {
        label.attributedText = NSAttributedString(string: "-")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadAttributedText()
        }
    }
}
