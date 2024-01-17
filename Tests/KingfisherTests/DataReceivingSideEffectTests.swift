
import XCTest
@testable import Kingfisher

class DataReceivingSideEffectTests: XCTestCase {

    var manager: KingfisherManager!

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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let uuid = UUID()
        let downloader = ImageDownloader(name: "test.manager.\(uuid.uuidString)")
        let cache = ImageCache(name: "test.cache.\(uuid.uuidString)")

        manager = KingfisherManager(downloader: downloader, cache: cache)
    }

    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        clearCaches([manager.cache])
        cleanDefaultCache()
        manager = nil
        super.tearDown()
    }

    func xtestDataReceivingSideEffectBlockCanBeCalled() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let receiver = DataReceivingStub()

        let options: KingfisherOptionsInfo = [/*.onDataReceived([receiver]),*/ .waitForCache]
        KingfisherManager.shared.retrieveImage(with: url, options: options) {
            result in
            XCTAssertTrue(receiver.called)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func xtestDataReceivingSideEffectBlockCanBeCalledButNotApply() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let receiver = DataReceivingNotAppyStub()

        let options: KingfisherOptionsInfo = [/*.onDataReceived([receiver]),*/ .waitForCache]
        KingfisherManager.shared.retrieveImage(with: url, options: options) {
            result in
            XCTAssertTrue(receiver.called)
            XCTAssertFalse(receiver.appied)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}

class DataReceivingStub: DataReceivingSideEffect {
    var called: Bool = false
    var onShouldApply: () -> Bool = { return true }
    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data) {
        self.called = true
    }
}

class DataReceivingNotAppyStub: DataReceivingSideEffect {

    var called: Bool = false
    var appied: Bool = false

    var onShouldApply: () -> Bool = { return false }

    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data) {
        called = true
        if onShouldApply() {
            appied = true
        }
    }
}
