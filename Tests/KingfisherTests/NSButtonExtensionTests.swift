
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import XCTest
@testable import Kingfisher

class NSButtonExtensionTests: XCTestCase {

    var button: NSButton!

    override class func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }

    override class func tearDown() {
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        
        button = NSButton()
        KingfisherManager.shared.downloader = ImageDownloader(name: "testDownloader")
        KingfisherManager.shared.defaultOptions = [.waitForCache]
        
        cleanDefaultCache()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        LSNocilla.sharedInstance().clearStubs()
        button = nil
        cleanDefaultCache()
        KingfisherManager.shared.defaultOptions = .empty
        super.tearDown()
    }

    func testDownloadAndSetImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)
        
        var progressBlockIsCalled = false

        button.kf.setImage(with: url, progressBlock: { _, _ in progressBlockIsCalled = true }) {
            result in
            XCTAssertTrue(progressBlockIsCalled)
            
            let image = result.value?.image
            XCTAssertNotNil(image)
            XCTAssertTrue(image!.renderEqual(to: testImage))
            XCTAssertTrue(self.button.image!.renderEqual(to: testImage))
            XCTAssertEqual(result.value!.cacheType, .none)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDownloadAndSetAlternateImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        var progressBlockIsCalled = false
        button.kf.setAlternateImage(with: url, progressBlock: { _, _ in progressBlockIsCalled = true }) {
            result in
            XCTAssertTrue(progressBlockIsCalled)
            
            let image = result.value?.image
            XCTAssertNotNil(image)
            XCTAssertTrue(image!.renderEqual(to: testImage))
            XCTAssertTrue(self.button.alternateImage!.renderEqual(to: testImage))
            XCTAssertEqual(result.value!.cacheType, .none)
            
            exp.fulfill()

        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCacnelImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)
        
        button.kf.setImage(with: url, completionHandler: { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            delay(0.1) { exp.fulfill() }
        })
        
        self.button.kf.cancelImageDownloadTask()
        _ = stub.go()

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCacnelAlternateImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)
        
        button.kf.setAlternateImage(with: url, completionHandler: { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            delay(0.1) { exp.fulfill() }
        })
        
        self.button.kf.cancelAlternateImageDownloadTask()
        _ = stub.go()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSettingNilURL() {
        let exp = expectation(description: #function)
        let url: URL? = nil
        button.kf.setAlternateImage(with: url, progressBlock: { _, _ in XCTFail() }) {
            result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            
            guard case .imageSettingError(reason: .emptySource) = result.error! else {
                XCTFail()
                fatalError()
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSettingNonWorkingImageWithFailureImage() {
        let expectation = self.expectation(description: "wait for downloading image")
        let url = testURLs[0]
        stub(url, errorCode: 404)
        
        button.kf.setImage(with: url, options: [.onFailureImage(testImage)], completionHandler: { result in
            XCTAssertNil(result.value)
            expectation.fulfill()
        })
        
        XCTAssertNil(button.image)
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(testImage, button.image)
    }
    
    func testSettingNonWorkingAlternateImageWithFailureImage() {
        let expectation = self.expectation(description: "wait for downloading image")
        let url = testURLs[0]
        stub(url, errorCode: 404)
        
        button.kf.setAlternateImage(with: url, options: [.onFailureImage(testImage)], completionHandler:  { result in
            XCTAssertNil(result.value)
            expectation.fulfill()
        })
        
        XCTAssertNil(button.alternateImage)
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(testImage, button.alternateImage)
    }

}
#endif
