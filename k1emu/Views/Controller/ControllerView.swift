import SwiftUI
import UIKit
import WebKit

/// Reference controller. GAME is pure video — no controls inside.
/// Dots: cursor · CHIP-8 pad · browser. No − / +.
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

    private let yColor = Color(red: 1.0, green: 0.84, blue: 0.2)
    private let xColor = Color(red: 0.35, green: 0.85, blue: 0.95)
    private let bColor = Color(red: 0.95, green: 0.25, blue: 0.25)
    private let aColor = Color(red: 0.25, green: 0.85, blue: 0.45)
    private let shoulderFill = Color(red: 0.78, green: 0.82, blue: 0.88)

    private var hasLivePixels: Bool {
        (appState.usingBuiltinCore && chip8.isRunning) || (core.isRunning && fb.width > 0)
    }

    private var isChip8: Bool {
        appState.usingBuiltinCore || game.system.uppercased() == "CHIP8"
    }

    /// Sony systems use PlayStation glyphs and the matching libretro face-button IDs.
    private var isPlayStation: Bool {
        ["PSP", "PS1", "PSX", "PLAYSTATION", "PLAYSTATION 1"].contains(game.system.uppercased())
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            GeometryReader { geo in
                layout(in: geo.size)
            }

            // Cursor-mode ring
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
        let gap: CGFloat = landscape ? 14 : 16

        let sideCtrl: CGFloat = landscape ? 76 : 84
        let stickSize: CGFloat = landscape ? 90 : 102
        let faceR: CGFloat = landscape ? 17 : 19
        let bottomH: CGFloat = landscape ? 58 : 66
        let topH: CGFloat = 30

        // GAME only — never shares space with buttons
        let gameW = min(size.width - sideCtrl * 2 - gap * 3,
                        landscape ? size.width * 0.40 : size.width * 0.48)
        let gameH = gameW * 0.60

        return VStack(spacing: 0) {
            topBar.frame(height: topH).padding(.horizontal, 12)

            // Shoulders — spaced out to corners
            HStack {
                VStack(spacing: 6) {
                    ShoulderCap(label: "LT", color: shoulderFill)
                    ShoulderCap(label: "LB", color: shoulderFill)
                }
                Spacer(minLength: 40)
                VStack(spacing: 6) {
                    ShoulderCap(label: "RT", color: shoulderFill)
                    ShoulderCap(label: "RB", color: shoulderFill)
                }
            }
            .padding(.horizontal, landscape ? 44 : 52)
            .padding(.top, 8)

            Spacer(minLength: 10)

            // D-pad · GAME · face — clear gaps, nothing on GAME
            HStack(alignment: .center, spacing: gap) {
                RefDPad()
                    .frame(width: sideCtrl, height: sideCtrl)

                pureGameScreen
                    .frame(width: gameW, height: gameH)

                RefFaceButtons(y: yColor, x: xColor, b: bColor, a: aColor, radius: faceR, playStation: isPlayStation)
                    .frame(width: sideCtrl + 10, height: sideCtrl + 10)
            }
            .padding(.horizontal, gap)

            // Three dots ONLY — cursor · CHIP-8 pad · browser (no − / +)
            HStack(spacing: 18) {
                ModeDot(
                    active: appState.isMouseMode,
                    color: .cyan,
                    label: "cursor"
                ) {
                    haptic(.medium)
                    appState.isMouseMode.toggle()
                    if appState.isMouseMode {
                        appState.showKeyboardInPanel = false
                        appState.showBrowserInPanel = false
                    }
                }

                ModeDot(
                    active: appState.showKeyboardInPanel,
                    color: .orange,
                    label: "chip8"
                ) {
                    haptic(.medium)
                    appState.showKeyboardInPanel.toggle()
                    if appState.showKeyboardInPanel {
                        appState.showBrowserInPanel = false
                        appState.isMouseMode = false
                    }
                }

                ModeDot(
                    active: appState.showBrowserInPanel,
                    color: .purple,
                    label: "web"
                ) {
                    haptic(.medium)
                    appState.toggleBrowserPanel()
                    if appState.showBrowserInPanel {
                        appState.showKeyboardInPanel = false
                        appState.isMouseMode = false
                    }
                }
            }
            .padding(.top, 12)

            Spacer(minLength: 10)

            // Sticks + center panel (Browser or CHIP-8 pad)
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

    // MARK: - Top

    private var topBar: some View {
        HStack(spacing: 8) {
            IconBtn("line.3.horizontal") {
                haptic(.light)
                appState.showInGameMenu = true
            }
            Text(game.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.5))
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
                .foregroundStyle(.black.opacity(0.7))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.black.opacity(0.05)))
        }
        .buttonStyle(PressPopStyle())
    }

    // MARK: - Pure GAME (nothing else inside)

    private var pureGameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.16), radius: 8, y: 3)

            if hasLivePixels && showGamePanel {
                EmulatorScreenView()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(2)
            } else if showGamePanel {
                Text("GAME")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text("CONTROLLER")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        // Cursor mode: drag on GAME for pointer (visual only ring is global)
        .gesture(
            appState.isMouseMode
            ? DragGesture(minimumDistance: 0).onChanged { _ in
                // reserved for touch-pointer mapping later
              }
            : nil
        )
    }

    // MARK: - Center bottom panel

    @ViewBuilder
    private var centerPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

            if appState.showKeyboardInPanel {
                Chip8Keypad()
            } else if appState.showBrowserInPanel {
                InPanelBrowser()
            } else {
                Text(isChip8 ? "Browser · CHIP-8 pad" : "Browser")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Mode dots (cursor / chip8 / browser)

struct ModeDot: View {
    let active: Bool
    let color: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(active ? color : Color.black.opacity(0.55))
                .frame(width: 11, height: 11)
                .overlay(
                    Circle()
                        .stroke(active ? color : Color.clear, lineWidth: 2)
                        .frame(width: 18, height: 18)
                )
                .shadow(color: active ? color.opacity(0.55) : .clear, radius: 7)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressPopStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - CHIP-8 hex keypad (not a text keyboard)

struct Chip8Keypad: View {
    /// Standard CHIP-8 layout:
    /// 1 2 3 C
    /// 4 5 6 D
    /// 7 8 9 E
    /// A 0 B F
    private let rows: [[(String, Int)]] = [
        [("1", 1), ("2", 2), ("3", 3), ("C", 0xC)],
        [("4", 4), ("5", 5), ("6", 6), ("D", 0xD)],
        [("7", 7), ("8", 8), ("9", 9), ("E", 0xE)],
        [("A", 0xA), ("0", 0), ("B", 0xB), ("F", 0xF)],
    ]

    var body: some View {
        VStack(spacing: 3) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 3) {
                    ForEach(row, id: \.1) { label, key in
                        Chip8Key(label: label, key: key)
                    }
                }
            }
        }
        .padding(4)
    }
}

struct Chip8Key: View {
    let label: String
    let key: Int
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(pressed ? Color.orange.opacity(0.7) : Color.white.opacity(0.14))
            )
            .scaleEffect(pressed ? 0.92 : 1)
            .animation(.spring(response: 0.12, dampingFraction: 0.7), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            Chip8Core.shared.setKey(key, pressed: true)
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        Chip8Core.shared.setKey(key, pressed: false)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
            )
    }
}

// MARK: - Shoulders

struct ShoulderCap: View {
    let label: String
    let color: Color
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: label.hasSuffix("T") ? 52 : 56, height: label.hasSuffix("T") ? 20 : 22)
            .background(
                Group {
                    if label.hasSuffix("T") {
                        Capsule().fill(color)
                    } else {
                        RoundedRectangle(cornerRadius: 6).fill(color)
                    }
                }
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

// MARK: - D-pad

struct RefDPad: View {
    @State private var held = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.18)
                    .fill(Color.black)
                    .frame(width: s * 0.30, height: s)
                RoundedRectangle(cornerRadius: s * 0.18)
                    .fill(Color.black)
                    .frame(width: s, height: s * 0.30)
                Circle()
                    .fill(Color.black)
                    .frame(width: s * 0.22, height: s * 0.22)
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

// MARK: - Face

struct RefFaceButtons: View {
    let y: Color, x: Color, b: Color, a: Color
    var radius: CGFloat = 18
    var playStation: Bool = false

    var body: some View {
        let gap = radius * 2.2
        ZStack {
            // Libretro's standard layout maps X to the top, Y to the left,
            // A to the right, and B to the bottom. Sony glyphs follow the
            // physical PSP / PlayStation button positions.
            FaceButton(color: playStation ? x : y,
                       label: playStation ? "△" : "Y",
                       inputLabel: playStation ? "X" : "Y",
                       radius: radius).offset(y: -gap)
            FaceButton(color: playStation ? y : x,
                       label: playStation ? "□" : "X",
                       inputLabel: playStation ? "Y" : "X",
                       radius: radius).offset(x: -gap)
            FaceButton(color: playStation ? a : b,
                       label: playStation ? "○" : "B",
                       inputLabel: playStation ? "A" : "B",
                       radius: radius).offset(x: gap)
            FaceButton(color: playStation ? b : a,
                       label: playStation ? "×" : "A",
                       inputLabel: playStation ? "B" : "A",
                       radius: radius).offset(y: gap)
        }
    }
}

struct FaceButton: View {
    let color: Color
    let label: String
    var inputLabel: String? = nil
    let radius: CGFloat
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: radius * 0.72, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: radius * 2, height: radius * 2)
            .background(
                Circle()
                    .fill(color)
                    .shadow(color: color.opacity(pressed ? 0.55 : 0.22), radius: pressed ? 10 : 4, y: 2)
            )
            .scaleEffect(pressed ? 0.88 : 1)
            .animation(.spring(response: 0.13, dampingFraction: 0.6), value: pressed)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            if let id = InputBridge.faceId(inputLabel ?? label) {
                                InputBridge.shared.set(id, pressed: true)
                            }
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        if let id = InputBridge.faceId(inputLabel ?? label) {
                            InputBridge.shared.set(id, pressed: false)
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            )
    }
}

// MARK: - Stick

struct RefStick: View {
    @Binding var offset: CGSize
    var size: CGFloat = 100
    private var maxTravel: CGFloat { size * 0.22 }
    private var knob: CGFloat { size * 0.58 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(white: 0.72), lineWidth: size * 0.11)
                .background(Circle().fill(Color(white: 0.92)))
                .frame(width: size, height: size)
            Circle()
                .fill(Color.black)
                .frame(width: knob, height: knob)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            offset = CGSize(
                                width: max(-maxTravel, min(maxTravel, v.translation.width)),
                                height: max(-maxTravel, min(maxTravel, v.translation.height))
                            )
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                                offset = .zero
                            }
                        }
                )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Shared

struct PressPopStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.15, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct InPanelBrowser: View {
    @EnvironmentObject var appState: AppState
    @State private var url = URL(string: "https://search.brave.com")!

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MiniWebView(url: $url)
            Button { appState.showBrowserInPanel = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(6)
            }
        }
    }
}

struct MiniWebView: UIViewRepresentable {
    @Binding var url: URL
    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView()
        w.isOpaque = false
        w.backgroundColor = .black
        w.scrollView.isScrollEnabled = true
        w.load(URLRequest(url: url))
        return w
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url { uiView.load(URLRequest(url: url)) }
    }
}

struct ControllerSettingsModal: View {
    @Binding var isPresented: Bool
    var onQuit: () -> Void
    @EnvironmentObject var settings: SettingsStore
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { isPresented = false }
            VStack(spacing: 16) {
                Text("Settings").font(.title3.bold())
                Toggle("Show FPS", isOn: $settings.showFPS)
                Button(role: .destructive) { onQuit() } label: {
                    Label("Quit Game", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(32)
        }
    }
}
