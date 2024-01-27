
import XCTest
@testable import Kingfisher

class ImageCacheTests: XCTestCase {

    var cache: ImageCache!
    var observer: NSObjectProtocol!
    
    override func setUp() {
        super.setUp()

        let uuid = UUID().uuidString
        let cacheName = "test-\(uuid)"
        // ImageCache 里面, 会根据 Name, 来进行对应的文件路径的创建.
        cache = ImageCache(name: cacheName)
    }
    
    override func tearDown() {
        clearCaches([cache])
        cache = nil
        observer = nil

        super.tearDown()
    }
    
    func testInvalidCustomCachePath() {
        let customPath = "/path/to/image/cache"
        let url = URL(fileURLWithPath: customPath)
        // 使用, XCTAssertThrowsError 这种方法,  可以去测试带有 throw 的方法.
        // XCTAssertThrowsError 用来测试, 一定会抛出错误.
        // XCTAssertNoThrow 用来测试, 不会抛出错误.
        
        // 测试, 给一个非法的地址, 不能生成对应的 ImageCache.
        XCTAssertThrowsError(try ImageCache(name: "test", cacheDirectoryURL: url)) { error in
            guard case KingfisherError.cacheError(reason: .cannotCreateDirectory(let path, _)) = error else {
                XCTFail("Should be KingfisherError with cacheError reason.")
                return
            }
            XCTAssertEqual(path, customPath + "/com.onevcat.Kingfisher.ImageCache.test")
        }
    }

    func testCustomCachePath() {
        let cacheURL = try! FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let subFolder = cacheURL.appendingPathComponent("temp")

        let customPath = subFolder.path
        let cache = try! ImageCache(name: "test", cacheDirectoryURL: subFolder)
        // 测试, 使用 Test 为名称, 可以
        XCTAssertEqual(
            cache.diskStorage.directoryURL.path,
            (customPath as NSString).appendingPathComponent("com.onevcat.Kingfisher.ImageCache.test"))
        clearCaches([cache])
    }
    
    func testCustomCachePathByBlock() {
        // 可以在框架的基础上, 自己定义存图的位置.
        let cache = try! ImageCache(name: "test", cacheDirectoryURL: nil, diskCachePathClosure: { (url, path) -> URL in
            let modifiedPath = path + "-modified"
            return url.appendingPathComponent(modifiedPath, isDirectory: true)
        })
        let cacheURL = try! FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        XCTAssertEqual(
            cache.diskStorage.directoryURL.path,
            (cacheURL.path as NSString).appendingPathComponent("com.onevcat.Kingfisher.ImageCache.test-modified"))
        clearCaches([cache])
    }
    
    func testMaxCachePeriodInSecond() {
        // 在 Config 中修改了配置, 那么使用的地方, 可以直接看到影响.
        cache.diskStorage.config.expiration = .seconds(1)
        XCTAssertEqual(cache.diskStorage.config.expiration.timeInterval, 1)
    }
    
    func testMaxMemorySize() {
        cache.memoryStorage.config.totalCostLimit = 1
        XCTAssert(cache.memoryStorage.config.totalCostLimit == 1, "maxMemoryCost should be able to be set.")
    }
    
    func testMaxDiskCacheSize() {
        cache.diskStorage.config.sizeLimit = 1
        XCTAssert(cache.diskStorage.config.sizeLimit == 1, "maxDiskCacheSize should be able to be set.")
    }
    
    func testClearDiskCache() {
        // 对于这种异步的操作, 就是需要使用 expectation 才可以完成处理.
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
            self.cache.clearMemoryCache()
            let cacheResult = self.cache.imageCachedType(forKey: key)
            // 提前把内存缓存清理了, 然后得到的, 就应该是 disk 的缓存的.
            XCTAssertTrue(cacheResult.cached)
            XCTAssertEqual(cacheResult, .disk)
        
            // 然后把 disk 的也清理了, 得到的, 就应该是没有缓存的.
            self.cache.clearDiskCache {
                let cacheResult = self.cache.imageCachedType(forKey: key)
                XCTAssertFalse(cacheResult.cached)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler:nil)
    }
    
    func testClearMemoryCache() {
        // 上面的测试, 应该算已经测过这个场景了.
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
            self.cache.clearMemoryCache()
            self.cache.retrieveImage(forKey: key) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value?.cacheType, .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testNoImageFound() {
        let exp = expectation(description: #function)
        cache.retrieveImage(forKey: testKeys[0]) { result in
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.value!.image)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCachedFileDoesNotExist() {
        let URLString = testKeys[0]
        let url = URL(string: URLString)!

        let exists = cache.imageCachedType(forKey: url.cacheKey).cached
        XCTAssertFalse(exists)
    }
    
    func testStoreImageInMemory() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, forKey: key, toDisk: false) { _ in
            self.cache.retrieveImage(forKey: key) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value?.cacheType, .memory)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStoreMultipleImages() {
        let exp = expectation(description: #function)
        storeMultipleImages {
            let diskCachePath = self.cache.diskStorage.directoryURL.path
            var files: [String] = []
            do {
                files = try FileManager.default.contentsOfDirectory(atPath: diskCachePath)
            } catch _ {
                XCTFail()
            }
            XCTAssertEqual(files.count, testKeys.count)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCachedFileExists() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let url = URL(string: key)!
        
        let exists = cache.imageCachedType(forKey: url.cacheKey).cached
        XCTAssertFalse(exists)
        
        cache.retrieveImage(forKey: key) { result in
            switch result {
            case .success(let value):
                XCTAssertNil(value.image)
                XCTAssertEqual(value.cacheType, .none)
            case .failure:
                XCTFail()
                return
            }

            self.cache.store(testImage, forKey: key, toDisk: true) { _ in
                self.cache.retrieveImage(forKey: key) { result in

                    XCTAssertNotNil(result.value?.image)
                    XCTAssertEqual(result.value?.cacheType, .memory)

                    self.cache.clearMemoryCache()
                    self.cache.retrieveImage(forKey: key) { result in
                        XCTAssertNotNil(result.value?.image)
                        XCTAssertEqual(result.value?.cacheType, .disk)

                        exp.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCachedFileWithCustomPathExtensionExists() {
        cache.diskStorage.config.pathExtension = "jpg"
        let exp = expectation(description: #function)
        
        let key = testKeys[0]
        let url = URL(string: key)!

        cache.store(testImage, forKey: key, toDisk: true) { _ in
            let cachePath = self.cache.cachePath(forKey: url.cacheKey)
            XCTAssertTrue(cachePath.hasSuffix(".jpg"))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

  
    func testCachedImageIsFetchedSyncronouslyFromTheMemoryCache() {
        cache.store(testImage, forKey: testKeys[0], toDisk: false)
        var foundImage: KFCrossPlatformImage?
        cache.retrieveImage(forKey: testKeys[0]) { result in
            foundImage = result.value?.image
        }
        XCTAssertEqual(testImage, foundImage)
    }

    func testIsImageCachedForKey() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        XCTAssertFalse(cache.imageCachedType(forKey: key).cached)
        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
            XCTAssertTrue(self.cache.imageCachedType(forKey: key).cached)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCleanDiskCacheNotification() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        cache.diskStorage.config.expiration = .seconds(0.01)

        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
            self.observer = NotificationCenter.default.addObserver(
                forName: .KingfisherDidCleanDiskCache,
                object: self.cache,
                queue: .main) {
                    noti in
                    let receivedCache = noti.object as? ImageCache
                    XCTAssertNotNil(receivedCache)
                    XCTAssertTrue(receivedCache === self.cache)
                
                    guard let hashes = noti.userInfo?[KingfisherDiskCacheCleanedHashKey] as? [String] else {
                        XCTFail("Notification should contains Strings in key 'KingfisherDiskCacheCleanedHashKey'")
                        exp.fulfill()
                        return
                    }
                
                    XCTAssertEqual(hashes.count, 1)
                    XCTAssertEqual(hashes.first!, self.cache.hash(forKey: key))
                    guard let o = self.observer else { return }
                    NotificationCenter.default.removeObserver(o)
                    exp.fulfill()
                }

            delay(1) {
                self.cache.cleanExpiredDiskCache()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCannotRetrieveCacheWithProcessorIdentifier() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
            self.cache.retrieveImage(forKey: key, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value)
                XCTAssertNil(result.value!.image)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRetrieveCacheWithProcessorIdentifier() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            processorIdentifier: p.identifier,
            toDisk: true)
        {
            _ in
            self.cache.retrieveImage(forKey: key, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value?.image)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDefaultCache() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let cache = ImageCache.default
        cache.store(testImage, forKey: key) { _ in
            XCTAssertTrue(cache.memoryStorage.isCached(forKey: key))
            XCTAssertTrue(cache.diskStorage.isCached(forKey: key))
            cleanDefaultCache()
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveDiskCacheSynchronously() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, forKey: key, toDisk: true) { _ in
            var cacheType = self.cache.imageCachedType(forKey: key)
            XCTAssertEqual(cacheType, .memory)
            
            self.cache.memoryStorage.remove(forKey: key)
            cacheType = self.cache.imageCachedType(forKey: key)
            XCTAssertEqual(cacheType, .disk)
            
            var dispatched = false
            self.cache.retrieveImageInDiskCache(forKey: key, options:  [.loadDiskFileSynchronously]) {
                result in
                XCTAssertFalse(dispatched)
                exp.fulfill()
            }
            // This should be called after the completion handler above.
            dispatched = true
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveDiskCacheAsynchronously() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, forKey: key, toDisk: true) { _ in
            var cacheType = self.cache.imageCachedType(forKey: key)
            XCTAssertEqual(cacheType, .memory)
            
            self.cache.memoryStorage.remove(forKey: key)
            cacheType = self.cache.imageCachedType(forKey: key)
            XCTAssertEqual(cacheType, .disk)
            
            var dispatched = false
            self.cache.retrieveImageInDiskCache(forKey: key, options:  nil) {
                result in
                XCTAssertTrue(dispatched)
                exp.fulfill()
            }
            // This should be called before the completion handler above.
            dispatched = true
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    func testModifierShouldOnlyApplyForFinalResultWhenMemoryLoad() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        cache.store(testImage, original: testImageData, forKey: key) { _ in
            self.cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)]) { result in
                XCTAssertFalse(modifierCalled)
                XCTAssertEqual(result.value?.image?.renderingMode, .automatic)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testModifierShouldOnlyApplyForFinalResultWhenDiskLoad() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        cache.store(testImage, original: testImageData, forKey: key) { _ in
            self.cache.clearMemoryCache()
            self.cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)]) { result in
                XCTAssertFalse(modifierCalled)
                XCTAssertEqual(result.value?.image?.renderingMode, .automatic)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
#endif
    
    func testStoreToMemoryWithExpiration() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            options: KingfisherParsedOptionsInfo([.memoryCacheExpiration(.seconds(0.2))]),
            toDisk: true)
        {
            _ in
            XCTAssertEqual(self.cache.imageCachedType(forKey: key), .memory)
            delay(1) {
                XCTAssertEqual(self.cache.imageCachedType(forKey: key), .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreToDiskWithExpiration() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            options: KingfisherParsedOptionsInfo([.diskCacheExpiration(.expired)]),
            toDisk: true)
        {
            _ in
            XCTAssertEqual(self.cache.imageCachedType(forKey: key), .memory)
            self.cache.clearMemoryCache()
            XCTAssertEqual(self.cache.imageCachedType(forKey: key), .none)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCalculateDiskStorageSize() {
        let exp = expectation(description: #function)
        cache.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                XCTAssertEqual(size, 0)
                self.storeMultipleImages {
                    self.cache.calculateDiskStorageSize { result in
                        switch result {
                        case .success(let size):
                            XCTAssertEqual(size, UInt(testImagePNGData.count * testKeys.count))
                        case .failure:
                            XCTAssert(false)
                        }
                        exp.fulfill()
                    }
                }
            case .failure:
                XCTAssert(false)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDiskCacheStillWorkWhenFolderDeletedExternally() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let url = URL(string: key)!
        
        let exists = cache.imageCachedType(forKey: url.cacheKey)
        XCTAssertEqual(exists, .none)
        
        cache.store(testImage, forKey: key, toDisk: true) { _ in
            self.cache.retrieveImage(forKey: key) { result in

                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value?.cacheType, .memory)

                self.cache.clearMemoryCache()
                self.cache.retrieveImage(forKey: key) { result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertEqual(result.value?.cacheType, .disk)
                    self.cache.clearMemoryCache()
                    
                    try! FileManager.default.removeItem(at: self.cache.diskStorage.directoryURL)
                    
                    let exists = self.cache.imageCachedType(forKey: url.cacheKey)
                    XCTAssertEqual(exists, .none)
                    
                    self.cache.store(testImage, forKey: key, toDisk: true) { _ in
                        self.cache.clearMemoryCache()
                        let cacheType = self.cache.imageCachedType(forKey: url.cacheKey)
                        XCTAssertEqual(cacheType, .disk)
                        exp.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDiskCacheCalculateSizeWhenFolderDeletedExternally() {
        let exp = expectation(description: #function)
        
        let key = testKeys[0]
        
        cache.calculateDiskStorageSize { result in
            XCTAssertEqual(result.value, 0)
            
            self.cache.store(testImage, forKey: key, toDisk: true) { _ in
                self.cache.calculateDiskStorageSize { result in
                    XCTAssertEqual(result.value, UInt(testImagePNGData.count))
                    
                    try! FileManager.default.removeItem(at: self.cache.diskStorage.directoryURL)
                    self.cache.calculateDiskStorageSize { result in
                        XCTAssertEqual(result.value, 0)
                        exp.fulfill()
                    }
                    
                }
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    #if swift(>=5.5)
    #if canImport(_Concurrency)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testCalculateDiskStorageSizeAsync() async throws {
        let size = try await cache.diskStorageSize
        XCTAssertEqual(size, 0)
        _ = await storeMultipleImagesAsync()
        let sizeAfterStoreMultipleImages = try await cache.diskStorageSize
        XCTAssertEqual(sizeAfterStoreMultipleImages, UInt(testImagePNGData.count * testKeys.count))
    }
    #endif
    #endif
    
    // MARK: - Helper
    private func storeMultipleImages(_ completionHandler: @escaping () -> Void) {
        let group = DispatchGroup()
        testKeys.forEach {
            group.enter()
            cache.store(testImage, original: testImageData, forKey: $0, toDisk: true) { _ in
                group.leave()
            }
        }
        group.notify(queue: .main, execute: completionHandler)
    }

    #if swift(>=5.5)
    #if canImport(_Concurrency)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    private func storeMultipleImagesAsync() async {
        await withCheckedContinuation { continuation in
            storeMultipleImages {
                continuation.resume()
            }
        }
    }
    #endif
    #endif
}
