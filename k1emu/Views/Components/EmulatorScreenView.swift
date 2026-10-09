import SwiftUI
import UIKit

/// Pixel-perfect fill of the GAME panel using UIKit aspect-fill (no letterbox).
struct EmulatorScreenView: View {
    @ObservedObject private var chip8 = Chip8Core.shared
    @ObservedObject private var fb = FrameBuffer.shared
    @EnvironmentObject var appState: AppState

    var body: some View {
        PixelFillView(
            image: currentImage,
            frameID: appState.usingBuiltinCore ? chip8.frameID : fb.frameID
        )
        .background(Color.black)
    }

    private var currentImage: UIImage? {
        if appState.usingBuiltinCore, let cg = chip8.makeCGImage() {
            return UIImage(cgImage: cg)
        }
        if let cg = fb.makeCGImage() {
            return UIImage(cgImage: cg)
        }
        return nil
    }
}

/// UIImageView with scaleAspectFill — guaranteed edge-to-edge fill.
struct PixelFillView: UIViewRepresentable {
    let image: UIImage?
    let frameID: UInt64

    func makeUIView(context: Context) -> UIImageView {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = .black
        v.layer.magnificationFilter = .nearest
        v.layer.minificationFilter = .nearest
        return v
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
        uiView.contentMode = .scaleAspectFill
        uiView.clipsToBounds = true
    }
}
