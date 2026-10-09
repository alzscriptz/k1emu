import SwiftUI
import UIKit

/// Shows the FULL framebuffer inside GAME — no crop / no zoom.
/// Uses aspect-fit so both NDS screens stay visible.
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

    @ViewBuilder
    private func pixelImage(_ img: CGImage, in size: CGSize) -> some View {
        let iw = CGFloat(img.width)
        let ih = CGFloat(max(img.height, 1))
        // Fit entire image inside panel (letterbox if needed — never crop)
        let scale = min(size.width / iw, size.height / ih)
        let dw = iw * scale
        let dh = ih * scale

        Image(decorative: img, scale: 1.0)
            .resizable()
            .interpolation(.none)
            .frame(width: dw, height: dh)
            .frame(width: size.width, height: size.height) // centers
    }
}
