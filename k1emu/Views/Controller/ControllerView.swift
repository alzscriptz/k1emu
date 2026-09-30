import SwiftUI

/// Layout matches the reference image:
/// LT/LB · RT/RB on top, D-pad left, GAME center, YXBA right,
/// left stick · Browser · right stick on bottom.
struct ControllerView: View {
    let game: GameItem
    var showGamePanel: Bool = true

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    @State private var leftStick: CGSize = .zero
    @State private var rightStick: CGSize = .zero

    // Button colors from the photo
    private let yColor = Color(red: 1.0, green: 0.84, blue: 0.2)      // yellow
    private let xColor = Color(red: 0.35, green: 0.85, blue: 0.95)    // cyan
    private let bColor = Color(red: 0.95, green: 0.25, blue: 0.25)    // red
    private let aColor = Color(red: 0.25, green: 0.85, blue: 0.45)    // green
    private let shoulderColor = Color(red: 0.78, green: 0.82, blue: 0.88)

    var body: some View {
        ZStack {
            // Clean white / light background like the photo
            Color.white.ignoresSafeArea()

            if appState.isBrowserMode {
                BrowserModeView()
            } else {
                photoLayout
            }

            // FPS top-right
            VStack {
                HStack {
                    Spacer()
                    FPSOverlay()
                        .padding(.trailing, 14)
                        .padding(.top, 10)
                }
                Spacer()
            }

            if appState.isMouseMode {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue, lineWidth: 3)
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Exact photo layout
    private var photoLayout: some View {
        VStack(spacing: 0) {
            // Top bar: menu / TV / quit (small, not in photo but needed)
            HStack {
                Button { appState.showInGameMenu = true } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.45))
                        .frame(width: 36, height: 36)
                }
                Spacer()
                if settings.tvModeEnabled {
                    Button {
                        appState.isTVModeActive.toggle()
                    } label: {
                        Image(systemName: appState.isTVModeActive ? "iphone" : "tv")
                            .font(.body)
                            .foregroundStyle(.black.opacity(0.45))
                    }
                }
                Button { appState.quitGame() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.45))
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            Spacer(minLength: 8)

            // —— SHOULDERS: LT/LB ····· RT/RB ——
            HStack {
                VStack(spacing: 6) {
                    ShoulderPill(label: "LT", color: shoulderColor, isTrigger: true)
                    ShoulderPill(label: "LB", color: shoulderColor, isTrigger: false)
                }
                Spacer()
                VStack(spacing: 6) {
                    ShoulderPill(label: "RT", color: shoulderColor, isTrigger: true)
                    ShoulderPill(label: "RB", color: shoulderColor, isTrigger: false)
                }
            }
            .padding(.horizontal, 36)

            Spacer(minLength: 16)

            // —— MID: D-pad | GAME | YXBA ——
            HStack(alignment: .center, spacing: 12) {
                // D-pad (photo: plus shape, black)
                PhotoDPad()
                    .frame(width: 88, height: 88)

                // GAME screen (center black panel)
                gameScreen
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)

                // Face buttons diamond: Y top, X left, B right, A bottom
                PhotoFaceButtons(
                    y: yColor, x: xColor, b: bColor, a: aColor
                )
                .frame(width: 100, height: 100)
            }
            .padding(.horizontal, 16)

            // Three dots under GAME (like photo)
            HStack(spacing: 8) {
                Circle().fill(Color.black.opacity(0.35)).frame(width: 6, height: 6)
                Circle().fill(Color.black.opacity(0.35)).frame(width: 6, height: 6)
                Circle().fill(Color.black.opacity(0.35)).frame(width: 6, height: 6)
            }
            .padding(.top, 10)

            Spacer(minLength: 18)

            // —— BOTTOM: Left stick | Browser | Right stick ——
            HStack(alignment: .center, spacing: 16) {
                PhotoStick(offset: $leftStick)
                    .frame(width: 86, height: 86)

                // Browser button (center, black rounded rect)
                Button {
                    appState.isBrowserMode.toggle()
                } label: {
                    Text("Browser")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black)
                        )
                }

                PhotoStick(offset: $rightStick)
                    .frame(width: 86, height: 86)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 20)

            // Game name footer
            Text(game.name)
                .font(.caption2)
                .foregroundStyle(.black.opacity(0.4))
                .lineLimit(1)
                .padding(.bottom, 12)
        }
    }

    private var gameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black)

            if showGamePanel {
                VStack(spacing: 6) {
                    Text("GAME")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(game.displaySystem)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))

                    // Clean core status — no "framework" noise
                    if let name = CoreLoader.shared.loadedCoreName {
                        Text(cleanCoreName(name))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.green.opacity(0.85))
                    } else {
                        Text("No core loaded")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.orange.opacity(0.85))
                    }
                }
            } else {
                VStack(spacing: 4) {
                    Text("TV MODE")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("Game on external display")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    private func cleanCoreName(_ raw: String) -> String {
        var s = raw
        // Strip paths / framework noise
        if let last = s.split(separator: "/").last { s = String(last) }
        s = s.replacingOccurrences(of: ".framework", with: "")
        s = s.replacingOccurrences(of: ".dylib", with: "")
        // Fix common typo display
        if s.lowercased().contains("libdns") { s = "libnds" }
        return s
    }
}

// MARK: - Photo-matched components

struct ShoulderPill: View {
    let label: String
    let color: Color
    let isTrigger: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: isTrigger ? 52 : 56, height: isTrigger ? 22 : 26)
            .background(
                Group {
                    if isTrigger {
                        // Trapezoid-ish look for triggers
                        Capsule().fill(color)
                    } else {
                        RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color)
                    }
                }
            )
    }
}

struct PhotoDPad: View {
    var body: some View {
        ZStack {
            // Vertical arm
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black)
                .frame(width: 28, height: 84)
            // Horizontal arm
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black)
                .frame(width: 84, height: 28)
            // Center nub
            Circle()
                .fill(Color.black)
                .frame(width: 22, height: 22)
        }
    }
}

struct PhotoFaceButtons: View {
    let y: Color
    let x: Color
    let b: Color
    let a: Color

    var body: some View {
        ZStack {
            // Y top
            face(y, "Y").offset(y: -32)
            // X left
            face(x, "X").offset(x: -32)
            // B right
            face(b, "B").offset(x: 32)
            // A bottom
            face(a, "A").offset(y: 32)
        }
    }

    private func face(_ color: Color, _ label: String) -> some View {
        Text(label)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(color))
    }
}

struct PhotoStick: View {
    @Binding var offset: CGSize
    private let maxTravel: CGFloat = 22

    var body: some View {
        ZStack {
            // Outer ring (light gray like photo)
            Circle()
                .stroke(Color(white: 0.75), lineWidth: 8)
                .background(Circle().fill(Color(white: 0.92)))

            // Inner black stick
            Circle()
                .fill(Color.black)
                .frame(width: 52, height: 52)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let x = max(-maxTravel, min(maxTravel, value.translation.width))
                            let y = max(-maxTravel, min(maxTravel, value.translation.height))
                            offset = CGSize(width: x, height: y)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.25)) {
                                offset = .zero
                            }
                        }
                )
        }
    }
}
