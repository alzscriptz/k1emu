import SwiftUI
import UIKit

/// Displays real pixel buffers from Chip8Core (or later libretro frames).
struct EmulatorScreenView: View {
    @ObservedObject var chip8 = Chip8Core.shared

    var body: some View {
        GeometryReader { geo in
            if let img = chip8.makeCGImage() {
                Image(decorative: img, scale: 1.0)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(64.0 / 32.0, contentMode: .fit)
                    .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                    .frame(width: geo.size.width, height: geo.size.height)
            } else {
                Color.black
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .id(chip8.frameID) // force refresh every emulated frame
    }
}
