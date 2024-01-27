
import Foundation

private let sharedProcessingQueue: CallbackQueue =
    .dispatch(DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Process"))

// Handles image processing work on an own process queue.
class ImageDataProcessor {
    let data: Data
    let callbacks: [SessionDataTask.TaskCallback]
    let queue: CallbackQueue

    // Note: We have an optimization choice there, to reduce queue dispatch by checking callback
    // queue settings in each option...
    let onImageProcessed = Delegate<(Result<KFCrossPlatformImage, KingfisherError>, SessionDataTask.TaskCallback), Void>()

    init(data: Data, callbacks: [SessionDataTask.TaskCallback], processingQueue: CallbackQueue?) {
        self.data = data
        self.callbacks = callbacks
        self.queue = processingQueue ?? sharedProcessingQueue
    }

    func process() {
        queue.execute(doProcess)
    }

    private func doProcess() {
        var processedImages = [String: KFCrossPlatformImage]()
        for callback in callbacks {
            // 每一种下图请求, 都可以配置自己的生成图片的算法.
            // 所以, 这里是一步步的, 通过自己下图请求的配置生成图片, 然后回传.
            let processor = callback.options.processor
            // 这里是为了避免, 重复生成. 因为, 同样的一个 Processor, 面对同样的一份 data, 一定是生成同样的一份 UIIMAGE
            var image = processedImages[processor.identifier]
            if image == nil {
                image = processor.process(item: .data(data), options: callback.options)
                processedImages[processor.identifier] = image
            }

            let result: Result<KFCrossPlatformImage, KingfisherError>
            if let image = image {
                let finalImage = callback.options.backgroundDecode ? image.kf.decoded : image
                result = .success(finalImage)
            } else {
                let error = KingfisherError.processorError(
                    reason: .processingFailed(processor: processor, item: .data(data)))
                result = .failure(error)
            }
            onImageProcessed.call((result, callback))
        }
    }
}
