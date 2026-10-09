import SwiftUI
import UIKit
import WebKit

/// Perfect match to the reference controller mockup.
/// White canvas · trapezoid LT/RT · LB/RB · star D-pad · wide GAME · YXBA · 3 dots · sticks + Browser
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

    private var scheme: FaceScheme { FaceScheme.forSystem(game.system) }

    var body: some View {
        ZStack {
            // Soft white like the mockup
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
        let sideCtrl: CGFloat = landscape ? 72 : 80
        let stickSize: CGFloat = landscape ? 90 : 102
        let faceR: CGFloat = landscape ? 16 : 18
        let bottomH: CGFloat = landscape ? 54 : 62
        let topH: CGFloat = 26

        // Wide GAME panel like the mockup (horizontal black window)
        let maxGameW = size.width - sideCtrl * 2 - 36
        let gameW = min(maxGameW, landscape ? size.width * 0.48 : size.width * 0.52)
        let gameH = min(gameW * 0.62, size.height * 0.36)

        return VStack(spacing: 0) {
            topBar.frame(height: topH).padding(.horizontal, 12)

            // LT/RT trapezoids + LB/RB bars — mockup style
            HStack {
                VStack(spacing: 5) {
                    TrapezoidShoulder(label: scheme.l2Label, color: shoulderFill)
                    ShoulderCap(label: scheme.l1Label, color: shoulderFill)
                }
                Spacer(minLength: 40)
                VStack(spacing: 5) {
                    TrapezoidShoulder(label: scheme.r2Label, color: shoulderFill)
                    ShoulderCap(label: scheme.r1Label, color: shoulderFill)
                }
            }
            .padding(.horizontal, landscape ? 40 : 50)
            .padding(.top, 8)

            Spacer(minLength: 10)

            // D-pad · GAME · face
            HStack(alignment: .center, spacing: 14) {
                StarDPad()
                    .frame(width: sideCtrl, height: sideCtrl)

                // THE game window — black rounded rect, video inside
                pureGameScreen
                    .frame(width: gameW, height: gameH)

                SystemFaceButtons(scheme: scheme, radius: faceR)
                    .frame(width: sideCtrl + 10, height: sideCtrl + 10)
            }
            .padding(.horizontal, 12)

            // Three dots under GAME
            HStack(spacing: 16) {
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

            Spacer(minLength: 10)

            // Sticks + Browser
            HStack(alignment: .center, spacing: 14) {
                RefStick(offset: $leftStick, size: stickSize)
                centerPanel
                    .frame(maxWidth: .infinity)
                    .frame(height: bottomH)
                RefStick(offset: $rightStick, size: stickSize)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
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
                .foregroundStyle(.black.opacity(0.35))
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
                .foregroundStyle(.black.opacity(0.55))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.black.opacity(0.05)))
        }
        .buttonStyle(PressPopStyle())
    }

    /// Black GAME window — this is where the ROM renders
    private var pureGameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)

            if hasLivePixels && showGamePanel {
                EmulatorScreenView()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(3)
            } else if showGamePanel {
                Text("GAME")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(2)
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
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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

// MARK: - Trapezoid LT / RT (mockup shape)

struct TrapezoidShoulder: View {
    let label: String
    let color: Color
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: 56, height: 22)
            .background(
                TrapezoidShape()
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

struct TrapezoidShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = rect.width * 0.12
        p.move(to: CGPoint(x: inset, y: 0))
        p.addLine(to: CGPoint(x: rect.width - inset, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}

// MARK: - Star / cross D-pad (mockup: bulbous ends)

struct StarDPad: View {
    @State private var held = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Vertical arm with round caps
                Capsule().fill(Color.black)
                    .frame(width: s * 0.28, height: s)
                // Horizontal arm
                Capsule().fill(Color.black)
                    .frame(width: s, height: s * 0.28)
                // Center disc
                Circle().fill(Color.black)
                    .frame(width: s * 0.32, height: s * 0.32)
            }
            .frame(width: s, height: s)
            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            .scaleEffect(held ? 0.95 : 1)
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
