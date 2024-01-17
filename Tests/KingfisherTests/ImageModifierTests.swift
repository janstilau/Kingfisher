
import XCTest
import Kingfisher

class ImageModifierTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAnyImageModifier() {
        let m = AnyImageModifier { image in
            return image
        }
        let image = KFCrossPlatformImage(data: testImagePNGData)!
        let modifiedImage = m.modify(image)
        XCTAssert(modifiedImage == image)
    }

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    func testRenderingModeImageModifier() {
        let m1 = RenderingModeImageModifier(renderingMode: .alwaysOriginal)
        let image = KFCrossPlatformImage(data: testImagePNGData)!
        let alwaysOriginalImage = m1.modify(image)
        XCTAssert(alwaysOriginalImage.renderingMode == .alwaysOriginal)

        let m2 = RenderingModeImageModifier(renderingMode: .alwaysTemplate)
        let alwaysTemplateImage = m2.modify(image)
        XCTAssert(alwaysTemplateImage.renderingMode == .alwaysTemplate)
    }

    func testFlipsForRightToLeftLayoutDirectionImageModifier() {
        let m = FlipsForRightToLeftLayoutDirectionImageModifier()
        let image = KFCrossPlatformImage(data: testImagePNGData)!
        let modifiedImage = m.modify(image)
        XCTAssert(modifiedImage.flipsForRightToLeftLayoutDirection == true)
    }

    func testAlignmentRectInsetsImageModifier() {
        let insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        let m = AlignmentRectInsetsImageModifier(alignmentInsets: insets)
        let image = KFCrossPlatformImage(data: testImagePNGData)!
        let modifiedImage = m.modify(image)
        XCTAssert(modifiedImage.alignmentRectInsets == insets)
    }

#endif

}
