
import SwiftUI
import UIKit

@available(iOS 14.0, *)
class SwiftUIViewController: UIHostingController<MainView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: MainView())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
