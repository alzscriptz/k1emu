import SwiftUI
import UIKit

/// Fills the GAME panel completely (scaledToFill — no empty bars).
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
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else if let img = fb.makeCGImage() {
                    Image(decorative: img, scale: 1.0)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color.black)
        .clipped()
        .id(appState.usingBuiltinCore ? chip8.frameID : fb.frameID)
    }
}
