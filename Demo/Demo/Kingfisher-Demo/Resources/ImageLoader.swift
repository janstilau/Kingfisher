
import Foundation

struct ImageLoader {
    static let sampleImageURLs: [URL] = {
        let prefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading"
        return (1...10).map { URL(string: "\(prefix)/kingfisher-\($0).jpg")! }
    }()
    
    static let orientationImageURLs: [URL] = {
        let prefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Orientation"
        return (1...16).map { URL(string: "\(prefix)/\($0).jpg")! }
    }()

    static let highResolutionImageURLs: [URL] = {
        let prefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/HighResolution"
        return (1...20).map { URL(string: "\(prefix)/\($0).jpg")! }
    }()
    
    static let gifImageURLs: [URL] = {
        let prefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF"
        return (1...3).map { URL(string: "\(prefix)/\($0).gif")! }
    }()

    static let progressiveImageURL: URL = {
        let prefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Progressive"
        return URL(string: "\(prefix)/progressive.jpg")!
    }()
    
    static func roseImage(index: Int) -> URL {
        return URL(string: "https://github.com/onevcat/Flower-Data-Set/raw/master/rose/rose-\(index).jpg")!
    }
}
