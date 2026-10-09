import SwiftUI
import UIKit

/// Fills the GAME panel with live pixels (scaled to fit, no tiny strip).
struct EmulatorScreenView: View {
    @ObservedObject private var chip8 = Chip8Core.shared
    @ObservedObject private var fb = FrameBuffer.shared
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                if appState.usingBuiltinCore, let img = chip8.makeCGImage() {
                    Image(decorative: img, scale: 1.0)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                } else if let img = fb.makeCGImage() {
                    Image(decorative: img, scale: 1.0)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color.black)
        .clipped()
        .id(appState.usingBuiltinCore ? chip8.frameID : fb.frameID)
    }
}
