import SwiftUI
import UIKit
import WebKit

/// Full-screen-friendly controller. GAME is pure video.
struct ControllerView: View {
    let game: GameItem
    var showGamePanel: Bool = true

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject private var chip8 = Chip8Core.shared
    @ObservedObject private var fb = FrameBuffer.shared
    @ObservedObject private var core = CoreLoader.shared

    @State private var leftStick: CGSize = .zero
    @State private var rightStick: CGSize = .zero

    private let shoulderFill = Color(red: 0.78, green: 0.82, blue: 0.88)

    private var hasLivePixels: Bool {
        (appState.usingBuiltinCore && chip8.isRunning) || (core.isRunning && fb.width > 0)
    }

    private var isChip8: Bool {
        appState.usingBuiltinCore || game.system.uppercased() == "CHIP8"
    }

    private var scheme: FaceScheme { FaceScheme.forSystem(game.system) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                layout(in: geo.size)
            }

            if appState.isMouseMode {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.cyan.opacity(0.85), lineWidth: 3)
                    .padding(10)
                    .allowsHitTesting(false)
                    .shadow(color: .cyan.opacity(0.35), radius: 8)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onDisappear {
            InputBridge.shared.clearAll()
            Chip8Core.shared.clearKeys()
        }
    }

    private func layout(in size: CGSize) -> some View {
        let landscape = size.width > size.height
        let gap: CGFloat = landscape ? 10 : 12
        let sideCtrl: CGFloat = landscape ? 68 : 72
        let stickSize: CGFloat = landscape ? 82 : 92
        let faceR: CGFloat = landscape ? 15 : 17
        let bottomH: CGFloat = landscape ? 52 : 60
        let topH: CGFloat = 28

        let maxGameW = size.width - sideCtrl * 2 - gap * 2
        let gameW = landscape ? min(maxGameW, size.width * 0.62) : min(maxGameW, size.width * 0.72)
        let gameH = landscape ? min(gameW * 0.72, size.height * 0.55) : min(gameW * 0.80, size.height * 0.45)

        return VStack(spacing: 0) {
            topBar.frame(height: topH).padding(.horizontal, 10)

            HStack {
                VStack(spacing: 5) {
                    ShoulderCap(label: scheme.l2Label, color: shoulderFill)
                    ShoulderCap(label: scheme.l1Label, color: shoulderFill)
                }
                Spacer(minLength: 36)
                VStack(spacing: 5) {
                    ShoulderCap(label: scheme.r2Label, color: shoulderFill)
                    ShoulderCap(label: scheme.r1Label, color: shoulderFill)
                }
            }
            .padding(.horizontal, landscape ? 36 : 44)
            .padding(.top, 6)

            Spacer(minLength: 6)

            HStack(alignment: .center, spacing: gap) {
                RefDPad()
                    .frame(width: sideCtrl, height: sideCtrl)

                pureGameScreen
                    .frame(width: gameW, height: gameH)

                SystemFaceButtons(scheme: scheme, radius: faceR)
                    .frame(width: sideCtrl + 8, height: sideCtrl + 8)
            }
            .padding(.horizontal, gap)

            HStack(spacing: 18) {
                ModeDot(active: appState.isMouseMode, color: .cyan, label: "cursor") {
                    haptic(.medium)
                    appState.isMouseMode.toggle()
                    if appState.isMouseMode {
                        appState.showKeyboardInPanel = false
                        appState.showBrowserInPanel = false
                    }
                }
                ModeDot(active: appState.showKeyboardInPanel, color: .orange, label: "chip8") {
                    haptic(.medium)
                    appState.showKeyboardInPanel.toggle()
                    if appState.showKeyboardInPanel {
                        appState.showBrowserInPanel = false
                        appState.isMouseMode = false
                    }
                }
                ModeDot(active: appState.showBrowserInPanel, color: .purple, label: "web") {
                    haptic(.medium)
                    appState.toggleBrowserPanel()
                    if appState.showBrowserInPanel {
                        appState.showKeyboardInPanel = false
                        appState.isMouseMode = false
                    }
                }
            }
            .padding(.top, 10)

            Spacer(minLength: 6)

            HStack(alignment: .center, spacing: 12) {
                RefStick(offset: $leftStick, size: stickSize)
                centerPanel
                    .frame(maxWidth: .infinity)
                    .frame(height: bottomH)
                RefStick(offset: $rightStick, size: stickSize)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .frame(width: size.width, height: size.height)
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            IconBtn("line.3.horizontal") {
                haptic(.light)
                appState.showInGameMenu = true
            }
            Text(game.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            IconBtn(appState.isTVModeActive ? "tv.fill" : "tv") {
                haptic(.medium)
                appState.isTVModeActive.toggle()
            }
            IconBtn("xmark") {
                haptic(.medium)
                appState.quitGame()
            }
        }
    }

    private func IconBtn(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
        .buttonStyle(PressPopStyle())
    }

    private var pureGameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 3)

            if hasLivePixels && showGamePanel {
                EmulatorScreenView()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(2)
            } else if showGamePanel {
                Text("GAME")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            } else {
                Text("CONTROLLER")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    @ViewBuilder
    private var centerPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))

            if appState.showKeyboardInPanel {
                Chip8Keypad()
            } else if appState.showBrowserInPanel {
                InPanelBrowser()
            } else {
                Text(isChip8 ? "Browser · CHIP-8 pad" : "Browser")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
