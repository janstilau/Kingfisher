
import XCTest
@testable import Kingfisher

class ImageDrawingTests: XCTestCase {

    func testImageResizing() {
        let result = testImage.kf.resize(to: CGSize(width: 20, height: 20))
        XCTAssertEqual(result.size, CGSize(width: 20, height: 20))
    }
    
    func testImageCropping() {
        let result = testImage.kf.crop(to: CGSize(width: 20, height: 20), anchorOn: .zero)
        XCTAssertEqual(result.size, CGSize(width: 20, height: 20))
    }
    
    func testImageScaling() {
        XCTAssertEqual(testImage.kf.scale, 1)
        let result = testImage.kf.scaled(to: 2.0)
        #if os(macOS)
        // No scale supported on macOS.
        XCTAssertEqual(result.kf.scale, 1)
        XCTAssertEqual(result.size.height, testImage.size.height)
        #else
        XCTAssertEqual(result.kf.scale, 2)
        XCTAssertEqual(result.size.height, testImage.size.height / 2)
        #endif
    }
}
