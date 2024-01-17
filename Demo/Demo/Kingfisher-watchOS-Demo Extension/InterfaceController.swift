

import WatchKit
import Foundation
import Kingfisher

var count = 0

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var interfaceImage: WKInterfaceImage!
    
    var currentIndex: Int?
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        currentIndex = count
        count += 1
    }
    
    func refreshImage() {
        let url = URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-\(currentIndex! + 1).jpg")!
        print("Start loading... \(url)")
        interfaceImage.kf.setImage(with: url) { r in
            print(r)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        refreshImage()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
