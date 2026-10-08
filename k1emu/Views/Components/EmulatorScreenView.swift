import SwiftUI
import UIKit

/// Shows Chip-8 OR libretro FrameBuffer pixels in the GAME panel / TV surface.
struct EmulatorScreenView: View {
    @ObservedObject private var chip8 = Chip8Core.shared
    @ObservedObject private var fb = FrameBuffer.shared
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geo in
            Group {
                if appState.usingBuiltinCore, let img = chip8.makeCGImage() {
                    Image(decorative: img, scale: 1.0)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(max(1, CGFloat(chip8.makeCGImage()?.width ?? 64)) / max(1, CGFloat(chip8.makeCGImage()?.height ?? 32)), contentMode: .fit)
                } else if let img = fb.makeCGImage() {
                    Image(decorative: img, scale: 1.0)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(CGFloat(fb.width) / max(1, CGFloat(fb.height)), contentMode: .fit)
                } else {
                    Color.black
                }
            }
            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color.black)
        .id(appState.usingBuiltinCore ? chip8.frameID : fb.frameID)
    }
}
