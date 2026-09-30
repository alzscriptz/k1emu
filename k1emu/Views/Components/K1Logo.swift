import SwiftUI

struct K1Logo: View {
    var size: CGFloat = 44
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [settings.accentColor, settings.accentColor.opacity(0.55), .cyan.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: settings.accentColor.opacity(0.42), radius: size * 0.18, y: size * 0.08)

            HStack(spacing: size * 0.02) {
                Text("K")
                    .font(.system(size: size * 0.42, weight: .black, design: .rounded))
                Text("1")
                    .font(.system(size: size * 0.42, weight: .black, design: .rounded))
                    .foregroundStyle(settings.joystickAccent)
            }
            .foregroundStyle(.white)
            .minimumScaleFactor(0.6)
        }
        .accessibilityLabel("K1")
    }
}

struct FPSOverlay: View {
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var monitor = FPSMonitor.shared

    var body: some View {
        if settings.showFPS {
            Group {
                if monitor.fps > 0 {
                    Text("\(monitor.fps.rounded().formatted(.number.precision(.fractionLength(0)))) FPS")
                } else {
                    Text("-- FPS")
                }
            }
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(fpsColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(fpsColor.opacity(0.4), lineWidth: 1))
            .onAppear { monitor.start() }
            .onDisappear { monitor.stop() }
        }
    }

    private var fpsColor: Color {
        guard monitor.fps > 0 else { return .white.opacity(0.7) }
        if monitor.fps >= 58 { return .green }
        if monitor.fps >= 45 { return .yellow }
        return .red
    }
}
