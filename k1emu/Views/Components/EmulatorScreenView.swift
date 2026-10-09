import SwiftUI
import UIKit

/// Correct aspect — full frame visible, no stretch, no crop.
struct EmulatorScreenView: View {
    @ObservedObject private var chip8 = Chip8Core.shared
    @ObservedObject private var fb = FrameBuffer.shared
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                if appState.usingBuiltinCore, let img = chip8.makeCGImage() {
                    pixelImage(img, in: geo.size)
                } else if let img = fb.makeCGImage() {
                    pixelImage(img, in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color.black)
        .clipped()
        .id(appState.usingBuiltinCore ? chip8.frameID : fb.frameID)
    }

    private func pixelImage(_ img: CGImage, in size: CGSize) -> some View {
        let iw = CGFloat(img.width)
        let ih = CGFloat(max(img.height, 1))
        let scale = min(size.width / iw, size.height / ih)
        let dw = iw * scale
        let dh = ih * scale

        return Image(decorative: img, scale: 1.0)
            .resizable()
            .interpolation(.none)
            .frame(width: dw, height: dh)
            .frame(maxWidth: .infinity, maxHeight: .infinity) // center
    }
}
