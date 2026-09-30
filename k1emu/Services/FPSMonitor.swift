import Foundation
import QuartzCore
import Combine

/// Measures real display callback cadence. It never fabricates FPS values.
final class FPSMonitor: NSObject, ObservableObject {
    static let shared = FPSMonitor()

    @Published private(set) var fps: Double = 0

    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var windowStart: CFTimeInterval = 0

    @MainActor
    func start() {
        stop()
        frameCount = 0
        windowStart = 0

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 0)
        } else {
            link.preferredFramesPerSecond = 60
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @MainActor
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        frameCount = 0
        windowStart = 0
        fps = 0
    }

    @MainActor
    @objc private func tick(_ link: CADisplayLink) {
        if windowStart == 0 {
            windowStart = link.timestamp
            frameCount = 0
        }

        frameCount += 1
        let elapsed = link.timestamp - windowStart
        guard elapsed >= 0.75 else { return }

        fps = Double(frameCount) / elapsed
        frameCount = 0
        windowStart = link.timestamp
    }

    deinit {
        displayLink?.invalidate()
    }
}
