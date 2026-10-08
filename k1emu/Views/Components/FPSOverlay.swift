import SwiftUI

struct FPSOverlay: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var fps: Int = 60

    var body: some View {
        if settings.showFPS {
            Text("\(fps) FPS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .onAppear {
                    // Display-only counter until a real core drives frame callbacks
                    fps = 60
                }
        }
    }
}
