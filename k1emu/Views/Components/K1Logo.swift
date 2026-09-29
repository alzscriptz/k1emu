import SwiftUI

/// App logo mark used on home, settings, and about.
struct K1Logo: View {
    var size: CGFloat = 44
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            settings.accentColor,
                            settings.accentColor.opacity(0.55),
                            Color.cyan.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: settings.accentColor.opacity(0.45), radius: 10, y: 4)

            // Stylized "K1" mark
            Text("K1")
                .font(.system(size: size * 0.38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
    }
}

struct FPSOverlay: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var appState: AppState
    @State private var fps: Double = 60
    @State private var timer: Timer?

    var body: some View {
        if settings.showFPS {
            Text(String(format: "%.0f FPS", fps))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(fpsColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(fpsColor.opacity(0.4), lineWidth: 1))
                .onAppear { start() }
                .onDisappear { timer?.invalidate() }
        }
    }

    private var fpsColor: Color {
        if fps >= 55 { return .green }
        if fps >= 40 { return .yellow }
        return .red
    }

    private func start() {
        // Simulated FPS tied to gameplay speed until real core is wired
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let base = 60.0 * appState.gameplaySpeed
            let jitter = Double.random(in: -1.5...1.5)
            fps = max(1, min(120, base + jitter))
        }
    }
}
