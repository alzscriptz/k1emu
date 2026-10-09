import SwiftUI
import UIKit
import WebKit

/// Layout matching user screenshot:
/// White bg · LT/LB · RT/RB pills · black cross D-pad · tall GAME · ABXY · sticks + Browser
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
    @State private var cursorPos: CGPoint = CGPoint(x: 0.5, y: 0.5)

    private let shoulderFill = Color(red: 0.78, green: 0.82, blue: 0.88)

    private var hasLivePixels: Bool {
        (appState.usingBuiltinCore && chip8.isRunning) || (core.isRunning && fb.width > 0)
    }

    private var isChip8: Bool {
        appState.usingBuiltinCore || game.system.uppercased() == "CHIP8"
    }

    private var isHandheldTall: Bool {
        let s = game.system.uppercased()
        return ["NDS", "DSI", "GB", "GBC", "GBA", "PSP", "POKEMINI", "VB"].contains(s)
    }

    private var scheme: FaceScheme { FaceScheme.forSystem(game.system) }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            GeometryReader { geo in
                layout(in: geo.size)
            }

            if appState.showBrowserInPanel {
                FullBrowserSheet()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(50)
            }

            if appState.isMouseMode && showGamePanel {
                GeometryReader { geo in
                    Circle()
                        .stroke(Color.cyan, lineWidth: 2)
                        .background(Circle().fill(Color.cyan.opacity(0.35)))
                        .frame(width: 22, height: 22)
                        .position(x: cursorPos.x * geo.size.width, y: cursorPos.y * geo.size.height)
                        .allowsHitTesting(false)
                }
                .zIndex(40)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onChange(of: leftStick.width) { _, _ in updateCursor() }
        .onChange(of: leftStick.height) { _, _ in updateCursor() }
        .onDisappear {
            InputBridge.shared.clearAll()
            Chip8Core.shared.clearKeys()
        }
    }

    private func updateCursor() {
        guard appState.isMouseMode else { return }
        cursorPos.x = min(0.98, max(0.02, cursorPos.x + (leftStick.width / 90) * 0.04))
        cursorPos.y = min(0.98, max(0.02, cursorPos.y + (leftStick.height / 90) * 0.04))
    }

    private func layout(in size: CGSize) -> some View {
        let landscape = size.width > size.height
        let sideCtrl: CGFloat = landscape ? 70 : 78
        let stickSize: CGFloat = landscape ? 84 : 96
        let faceR: CGFloat = landscape ? 15 : 17
        let bottomH: CGFloat = landscape ? 52 : 58
        let topH: CGFloat = 26
        let shoulderH: CGFloat = 48
        let dotsH: CGFloat = 28

        let reservedH = topH + shoulderH + bottomH + dotsH + 24
        let availH = max(160, size.height - reservedH)
        let maxGameW = size.width - sideCtrl * 2 - 28

        var gameW: CGFloat
        var gameH: CGFloat
        if isHandheldTall {
            gameH = min(availH, size.height * 0.58)
            gameW = min(maxGameW, gameH * 0.78)
            if gameW >= maxGameW - 1 {
                gameW = maxGameW
                gameH = min(availH, gameW / 0.72)
            }
        } else {
            gameW = min(maxGameW, landscape ? size.width * 0.50 : size.width * 0.55)
            gameH = min(availH, gameW * 0.75)
        }

        return VStack(spacing: 0) {
            topBar.frame(height: topH).padding(.horizontal, 10)

            HStack {
                VStack(spacing: 4) {
                    ShoulderCap(label: scheme.l2Label, color: shoulderFill)
                    ShoulderCap(label: scheme.l1Label, color: shoulderFill)
                }
                Spacer(minLength: 24)
                VStack(spacing: 4) {
                    ShoulderCap(label: scheme.r2Label, color: shoulderFill)
                    ShoulderCap(label: scheme.r1Label, color: shoulderFill)
                }
            }
            .padding(.horizontal, landscape ? 36 : 44)
            .padding(.top, 4)
            .frame(height: shoulderH)

            Spacer(minLength: 4)

            HStack(alignment: .center, spacing: 10) {
                CrossDPad()
                    .frame(width: sideCtrl, height: sideCtrl)

                pureGameScreen
                    .frame(width: gameW, height: gameH)

                SystemFaceButtons(scheme: scheme, radius: faceR)
                    .frame(width: sideCtrl + 8, height: sideCtrl + 8)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 18) {
                ModeDot(active: appState.isMouseMode, color: .cyan, label: "cursor") {
                    haptic(.medium)
                    appState.isMouseMode.toggle()
                    if appState.isMouseMode {
                        appState.showKeyboardInPanel = false
                        appState.showBrowserInPanel = false
                    }
                }
                ModeDot(active: appState.showBrowserInPanel, color: .purple, label: "browser") {
                    haptic(.medium)
                    appState.showBrowserInPanel.toggle()
                    if appState.showBrowserInPanel {
                        appState.showKeyboardInPanel = false
                        appState.isMouseMode = false
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
            }
            .frame(height: dotsH)
            .padding(.top, 6)

            Spacer(minLength: 4)

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
                .foregroundStyle(.black.opacity(0.40))
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
                .foregroundStyle(.black.opacity(0.60))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.black.opacity(0.06)))
        }
        .buttonStyle(PressPopStyle())
    }

    private var pureGameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)

            if hasLivePixels && showGamePanel {
                EmulatorScreenView()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(1)
            } else if showGamePanel {
                Text("GAME")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text("CONTROLLER")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    @ViewBuilder
    private var centerPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black)

            if appState.showKeyboardInPanel {
                Chip8Keypad()
            } else {
                Text("Browser")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            if !appState.showKeyboardInPanel {
                haptic(.medium)
                appState.showBrowserInPanel = true
                appState.isMouseMode = false
                appState.showKeyboardInPanel = false
            }
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

struct CrossDPad: View {
    @State private var held = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Capsule().fill(Color.black)
                    .frame(width: s * 0.30, height: s)
                Capsule().fill(Color.black)
                    .frame(width: s, height: s * 0.30)
            }
            .frame(width: s, height: s)
            .scaleEffect(held ? 0.96 : 1)
            .animation(.spring(response: 0.14, dampingFraction: 0.7), value: held)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        held = true
                        let c = CGPoint(x: s / 2, y: s / 2)
                        let dx = v.location.x - c.x
                        let dy = v.location.y - c.y
                        let dead: CGFloat = 10
                        let ib = InputBridge.shared
                        ib.set(InputBridge.UP, pressed: dy < -dead)
                        ib.set(InputBridge.DOWN, pressed: dy > dead)
                        ib.set(InputBridge.LEFT, pressed: dx < -dead)
                        ib.set(InputBridge.RIGHT, pressed: dx > dead)
                    }
                    .onEnded { _ in
                        held = false
                        let ib = InputBridge.shared
                        ib.set(InputBridge.UP, pressed: false)
                        ib.set(InputBridge.DOWN, pressed: false)
                        ib.set(InputBridge.LEFT, pressed: false)
                        ib.set(InputBridge.RIGHT, pressed: false)
                    }
            )
        }
    }
}
