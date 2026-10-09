import SwiftUI
import UIKit
import WebKit

/// Controller matching the reference layout exactly.
/// White background · LT/RT triangles · LB/RB · cross D-pad · GAME · face diamond
/// Three dots under GAME: 1 Cursor · 2 Browser · 3 CHIP-8 pad
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
                    let cx = cursorPos.x * geo.size.width
                    let cy = cursorPos.y * geo.size.height
                    Circle()
                        .stroke(Color.cyan, lineWidth: 2)
                        .background(Circle().fill(Color.cyan.opacity(0.35)))
                        .frame(width: 22, height: 22)
                        .position(x: cx, y: cy)
                        .allowsHitTesting(false)
                }
                .zIndex(40)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onChange(of: leftStick) { _ in
            guard appState.isMouseMode else { return }
            let dx = leftStick.width / 90
            let dy = leftStick.height / 90
            cursorPos.x = min(0.98, max(0.02, cursorPos.x + dx * 0.04))
            cursorPos.y = min(0.98, max(0.02, cursorPos.y + dy * 0.04))
        }
        .onDisappear {
            InputBridge.shared.clearAll()
            Chip8Core.shared.clearKeys()
        }
    }

    private func layout(in size: CGSize) -> some View {
        let landscape = size.width > size.height
        let gap: CGFloat = landscape ? 12 : 14
        let sideCtrl: CGFloat = landscape ? 74 : 82
        let stickSize: CGFloat = landscape ? 88 : 100
        let faceR: CGFloat = landscape ? 16 : 18
        let bottomH: CGFloat = landscape ? 56 : 64
        let topH: CGFloat = 28

        let gameW = min(size.width - sideCtrl * 2 - gap * 2.5,
                        landscape ? size.width * 0.42 : size.width * 0.50)
        let gameH = gameW * 0.62

        return VStack(spacing: 0) {
            topBar.frame(height: topH).padding(.horizontal, 12)

            HStack {
                VStack(spacing: 5) {
                    TriangleShoulder(label: scheme.l2Label, color: shoulderFill)
                    ShoulderCap(label: scheme.l1Label, color: shoulderFill)
                }
                Spacer(minLength: 40)
                VStack(spacing: 5) {
                    TriangleShoulder(label: scheme.r2Label, color: shoulderFill)
                    ShoulderCap(label: scheme.r1Label, color: shoulderFill)
                }
            }
            .padding(.horizontal, landscape ? 40 : 48)
            .padding(.top, 6)

            Spacer(minLength: 8)

            HStack(alignment: .center, spacing: gap) {
                CrossDPad()
                    .frame(width: sideCtrl, height: sideCtrl)

                pureGameScreen
                    .frame(width: gameW, height: gameH)

                SystemFaceButtons(scheme: scheme, radius: faceR)
                    .frame(width: sideCtrl + 10, height: sideCtrl + 10)
            }
            .padding(.horizontal, gap)

            HStack(spacing: 20) {
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
            .padding(.top, 12)

            Spacer(minLength: 8)

            HStack(alignment: .center, spacing: 14) {
                RefStick(offset: $leftStick, size: stickSize)
                centerPanel
                    .frame(maxWidth: .infinity)
                    .frame(height: bottomH)
                RefStick(offset: $rightStick, size: stickSize)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
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
                .foregroundStyle(.black.opacity(0.45))
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
                .foregroundStyle(.black.opacity(0.65))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.black.opacity(0.06)))
        }
        .buttonStyle(PressPopStyle())
    }

    private var pureGameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)

            if hasLivePixels && showGamePanel {
                EmulatorScreenView()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(2)
            } else if showGamePanel {
                Text("GAME")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
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
                .fill(Color.black)
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)

            if appState.showKeyboardInPanel {
                Chip8Keypad()
            } else {
                Text("Browser")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

// MARK: - Triangle shoulder (LT / RT from reference)

struct TriangleShoulder: View {
    let label: String
    let color: Color
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: 54, height: 20)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 10, bottomLeadingRadius: 4,
                    bottomTrailingRadius: 4, topTrailingRadius: 10
                )
                .fill(color)
            )
            .scaleEffect(pressed ? 0.92 : 1)
            .animation(.spring(response: 0.15, dampingFraction: 0.65), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            if let id = InputBridge.shoulderId(label) {
                                InputBridge.shared.set(id, pressed: true)
                            }
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        if let id = InputBridge.shoulderId(label) {
                            InputBridge.shared.set(id, pressed: false)
                        }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
            )
    }
}

// MARK: - Cross D-pad matching reference

struct CrossDPad: View {
    @State private var held = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Capsule().fill(Color.black)
                    .frame(width: s * 0.28, height: s)
                Capsule().fill(Color.black)
                    .frame(width: s, height: s * 0.28)
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
