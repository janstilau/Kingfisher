
#if !os(watchOS)
#if canImport(UIKit)
import UIKit
#else
import AppKit
import CoreVideo
#endif

protocol DisplayLinkCompatible: AnyObject {
    var isPaused: Bool { get set }
    
    var preferredFramesPerSecond: NSInteger { get }
    var timestamp: CFTimeInterval { get }
    var duration: CFTimeInterval { get }
    
    func add(to runLoop: RunLoop, forMode mode: RunLoop.Mode)
    func remove(from runLoop: RunLoop, forMode mode: RunLoop.Mode)
    
    func invalidate()
}

#if !os(macOS)
extension UIView {
    func compatibleDisplayLink(target: Any, selector: Selector) -> DisplayLinkCompatible {
        return CADisplayLink(target: target, selector: selector)
    }
}

extension CADisplayLink: DisplayLinkCompatible {}

#else
extension NSView {
    func compatibleDisplayLink(target: Any, selector: Selector) -> DisplayLinkCompatible {
#if swift(>=5.9) // macOS 14 SDK is included in Xcode 15, which comes with swift 5.9. Add this check to make old compilers happy.
        if #available(macOS 14.0, *) {
            return displayLink(target: target, selector: selector)
        } else {
            return DisplayLink(target: target, selector: selector)
        }
#else
        return DisplayLink(target: target, selector: selector)
#endif
    }
}

#if swift(>=5.9)
@available(macOS 14.0, *)
extension CADisplayLink: DisplayLinkCompatible {
    var preferredFramesPerSecond: NSInteger { return 0 }
}
#endif

class DisplayLink: DisplayLinkCompatible {
    private var link: CVDisplayLink?
    private var target: Any?
    private var selector: Selector?
    
    private var schedulers: [RunLoop: [RunLoop.Mode]] = [:]
    
    init(target: Any, selector: Selector) {
        self.target = target
        self.selector = selector
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        if let link = link {
            CVDisplayLinkSetOutputHandler(link, displayLinkCallback(_:inNow:inOutputTime:flagsIn:flagsOut:))
        }
    }
    
    deinit {
        self.invalidate()
    }
    
    private func displayLinkCallback(_ link: CVDisplayLink,
                                     inNow: UnsafePointer<CVTimeStamp>,
                                     inOutputTime: UnsafePointer<CVTimeStamp>,
                                     flagsIn: CVOptionFlags,
                                     flagsOut: UnsafeMutablePointer<CVOptionFlags>) -> CVReturn
    {
        let outputTime = inOutputTime.pointee
        DispatchQueue.main.async {
            guard let selector = self.selector, let target = self.target else { return }
            if outputTime.videoTimeScale != 0 {
                self.duration = CFTimeInterval(Double(outputTime.videoRefreshPeriod) / Double(outputTime.videoTimeScale))
            }
            if self.timestamp != 0 {
                for scheduler in self.schedulers {
                    scheduler.key.perform(selector, target: target, argument: nil, order: 0, modes: scheduler.value)
                }
            }
            self.timestamp = CFTimeInterval(Double(outputTime.hostTime) / 1_000_000_000)
        }
        return kCVReturnSuccess
    }
    
    var isPaused: Bool = true {
        didSet {
            guard let link = link else { return }
            if isPaused {
                if CVDisplayLinkIsRunning(link) {
                    CVDisplayLinkStop(link)
                }
            } else {
                if !CVDisplayLinkIsRunning(link) {
                    CVDisplayLinkStart(link)
                }
            }
        }
    }
    
    var preferredFramesPerSecond: NSInteger = 0
    var timestamp: CFTimeInterval = 0
    var duration: CFTimeInterval = 0
    
    func add(to runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        assert(runLoop == .main)
        schedulers[runLoop, default: []].append(mode)
    }
    
    func remove(from runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        schedulers[runLoop]?.removeAll { $0 == mode }
        if let modes = schedulers[runLoop], modes.isEmpty {
            schedulers.removeValue(forKey: runLoop)
        }
    }
    
    func invalidate() {
        schedulers = [:]
        isPaused = true
        target = nil
        selector = nil
        if let link = link {
            CVDisplayLinkSetOutputHandler(link) { _, _, _, _, _ in kCVReturnSuccess }
        }
    }
}
#endif
#endif
