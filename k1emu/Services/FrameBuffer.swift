import Foundation
import CoreGraphics
import UIKit
import Combine

/// Shared pixel buffer for libretro video_refresh → SwiftUI
@MainActor
final class FrameBuffer: ObservableObject {
    static let shared = FrameBuffer()

    @Published private(set) var frameID: UInt64 = 0
    @Published private(set) var width: Int = 0
    @Published private(set) var height: Int = 0

    private var rgba: [UInt8] = []

    /// Called from video callback (may be off-main — hop to main)
    nonisolated func update(data: UnsafeRawPointer?, width: Int, height: Int, pitch: Int, isRGB565: Bool) {
        guard let data, width > 0, height > 0, pitch > 0 else { return }

        var out = [UInt8](repeating: 0, count: width * height * 4)

        if isRGB565 {
            for y in 0..<height {
                let row = data.advanced(by: y * pitch).assumingMemoryBound(to: UInt16.self)
                for x in 0..<width {
                    let p = row[x]
                    let r = UInt8(((p >> 11) & 0x1F) * 255 / 31)
                    let g = UInt8(((p >> 5) & 0x3F) * 255 / 63)
                    let b = UInt8((p & 0x1F) * 255 / 31)
                    let o = (y * width + x) * 4
                    out[o] = r; out[o+1] = g; out[o+2] = b; out[o+3] = 255
                }
            }
        } else {
            // XRGB8888 or 0RGB8888 — 4 bytes per pixel, pitch in bytes
            for y in 0..<height {
                let row = data.advanced(by: y * pitch)
                for x in 0..<width {
                    let px = row.advanced(by: x * 4).assumingMemoryBound(to: UInt8.self)
                    // libretro often BGRA or XRGB little-endian: B G R X
                    let o = (y * width + x) * 4
                    out[o] = px[2]     // R
                    out[o+1] = px[1]   // G
                    out[o+2] = px[0]   // B
                    out[o+3] = 255
                }
            }
        }

        let w = width, h = height
        DispatchQueue.main.async {
            self.rgba = out
            self.width = w
            self.height = h
            self.frameID &+= 1
        }
    }

    func makeCGImage() -> CGImage? {
        guard width > 0, height > 0, rgba.count >= width * height * 4 else { return nil }
        let bpr = width * 4
        guard let provider = CGDataProvider(data: Data(rgba) as CFData) else { return nil }
        return CGImage(
            width: width, height: height,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bpr,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
    }

    func clear() {
        rgba = []
        width = 0
        height = 0
        frameID &+= 1
    }
}
