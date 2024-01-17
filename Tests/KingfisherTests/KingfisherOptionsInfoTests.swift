

import XCTest
@testable import Kingfisher

class KingfisherOptionsInfoTests: XCTestCase {

    func testEmptyOptionsShouldParseCorrectly() {
        let options = KingfisherParsedOptionsInfo(KingfisherOptionsInfo.empty)
        XCTAssertTrue(options.targetCache === nil)
        XCTAssertTrue(options.downloader === nil)

#if os(iOS) || os(tvOS) || os(visionOS)
        switch options.transition {
        case .none: break
        default: XCTFail("The transition for empty option should be .None. But \(options.transition)")
        }
#endif
        
        XCTAssertEqual(options.downloadPriority, URLSessionTask.defaultPriority)
        XCTAssertFalse(options.forceRefresh)
        XCTAssertFalse(options.fromMemoryCacheOrRefresh)
        XCTAssertFalse(options.cacheMemoryOnly)
        XCTAssertFalse(options.backgroundDecode)
        XCTAssertEqual(options.callbackQueue.queue.label, DispatchQueue.main.label)
        XCTAssertEqual(options.scaleFactor, 1.0)
        XCTAssertFalse(options.keepCurrentImageWhileLoading)
        XCTAssertFalse(options.onlyLoadFirstFrame)
        XCTAssertFalse(options.cacheOriginalImage)
        XCTAssertEqual(options.diskStoreWriteOptions, [])
    }
    
    func testSetOptionsShouldParseCorrectly() {
        let cache = ImageCache(name: "com.onevcat.Kingfisher.KingfisherOptionsInfoTests")
        let downloader = ImageDownloader(name: "com.onevcat.Kingfisher.KingfisherOptionsInfoTests")
        
        let queue = DispatchQueue.global(qos: .default)
        let testModifier = TestModifier()
        let testRedirectHandler = TestRedirectHandler()
        let processor = RoundCornerImageProcessor(cornerRadius: 20)
        let serializer = FormatIndicatedCacheSerializer.png
        let modifier = AnyImageModifier { i in return i }
        let alternativeSource = Source.network(URL(string: "https://onevcat.com")!)

        var options = KingfisherParsedOptionsInfo([
            .targetCache(cache),
            .downloader(downloader),
            .originalCache(cache),
            .downloadPriority(0.8),
            .forceRefresh,
            .forceTransition,
            .fromMemoryCacheOrRefresh,
            .cacheMemoryOnly,
            .waitForCache,
            .onlyFromCache,
            .backgroundDecode,
            .callbackQueue(.dispatch(queue)),
            .scaleFactor(2.0),
            .preloadAllAnimationData,
            .requestModifier(testModifier),
            .redirectHandler(testRedirectHandler),
            .processor(processor),
            .cacheSerializer(serializer),
            .imageModifier(modifier),
            .keepCurrentImageWhileLoading,
            .onlyLoadFirstFrame,
            .cacheOriginalImage,
            .diskStoreWriteOptions([.atomic]),
            .alternativeSources([alternativeSource]),
            .retryStrategy(DelayRetryStrategy(maxRetryCount: 10))
        ])
        
        XCTAssertTrue(options.targetCache === cache)
        XCTAssertTrue(options.originalCache === cache)
        XCTAssertTrue(options.downloader === downloader)

        #if os(iOS) || os(tvOS) || os(visionOS)
        let transition = ImageTransition.fade(0.5)
        options.transition = transition
        switch options.transition {
        case .fade(let duration): XCTAssertEqual(duration, 0.5)
        default: XCTFail()
        }
        #endif
        
        XCTAssertEqual(options.downloadPriority, 0.8)
        XCTAssertTrue(options.forceRefresh)
        XCTAssertTrue(options.fromMemoryCacheOrRefresh)
        XCTAssertTrue(options.forceTransition)
        XCTAssertTrue(options.cacheMemoryOnly)
        XCTAssertTrue(options.waitForCache)
        XCTAssertTrue(options.onlyFromCache)
        XCTAssertTrue(options.backgroundDecode)
        
        XCTAssertEqual(options.callbackQueue.queue.label, queue.label)
        XCTAssertEqual(options.scaleFactor, 2.0)
        XCTAssertTrue(options.preloadAllAnimationData)
        XCTAssertTrue(options.requestModifier is TestModifier)
        XCTAssertTrue(options.redirectHandler is TestRedirectHandler)
        XCTAssertEqual(options.processor.identifier, processor.identifier)
        XCTAssertTrue(options.cacheSerializer is FormatIndicatedCacheSerializer)
        XCTAssertTrue(options.imageModifier is AnyImageModifier)
        XCTAssertTrue(options.keepCurrentImageWhileLoading)
        XCTAssertTrue(options.onlyLoadFirstFrame)
        XCTAssertTrue(options.cacheOriginalImage)
        XCTAssertEqual(options.diskStoreWriteOptions, [Data.WritingOptions.atomic])
        XCTAssertEqual(options.alternativeSources?.count, 1)
        XCTAssertEqual(options.alternativeSources?.first?.url, alternativeSource.url)

        let retry = options.retryStrategy as? DelayRetryStrategy
        XCTAssertNotNil(retry)
        XCTAssertEqual(retry?.maxRetryCount, 10)
    }
    
    func testOptionCouldBeOverwritten() {
        var options = KingfisherParsedOptionsInfo([.downloadPriority(0.5), .onlyFromCache])
        XCTAssertEqual(options.downloadPriority, 0.5)

        options = KingfisherParsedOptionsInfo([.downloadPriority(0.5), .onlyFromCache, .downloadPriority(0.8)])
        XCTAssertEqual(options.downloadPriority, 0.8)
    }
}

class TestModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        return nil
    }
}

class TestRedirectHandler: ImageDownloadRedirectHandler {
    func handleHTTPRedirection(for task: SessionDataTask, response: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(newRequest)
    }
}
