import SwiftUI
import UIKit
import WebKit

/// Exact reference layout: shoulders · D-pad · GAME · ABXY · dots · sticks · Browser.
/// No overlap. Press VFX on every control.
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

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            GeometryReader { geo in
                layout(in: geo.size)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onDisappear { InputBridge.shared.clearAll() }
    }

    private func layout(in size: CGSize) -> some View {
        let landscape = size.width > size.height
        let pad: CGFloat = landscape ? 10 : 14

        // Fixed control sizes from reference proportions
        let sideCtrl: CGFloat = landscape ? 78 : 86
        let stickSize: CGFloat = landscape ? 88 : 100
        let faceR: CGFloat = landscape ? 16 : 18
        let browserH: CGFloat = landscape ? 56 : 64
        let topH: CGFloat = 28

        // GAME: centered, clear of D-pad / face
        let gameW = min(size.width - sideCtrl * 2 - pad * 3, landscape ? size.width * 0.42 : size.width * 0.50)
        let gameH = gameW * 0.62

        return VStack(spacing: 0) {
            // Top chrome (menu / title / tv / close) — thin, doesn't crowd GAME
            topBar
                .frame(height: topH)
                .padding(.horizontal, 12)

            // Shoulders — LT/RT triangles, LB/RB bars (match reference)
            HStack {
                VStack(spacing: 5) {
                    ShoulderCap(label: "LT", triangular: true, color: shoulderFill)
                    ShoulderCap(label: "LB", triangular: false, color: shoulderFill)
                }
                Spacer()
                VStack(spacing: 5) {
                    ShoulderCap(label: "RT", triangular: true, color: shoulderFill)
                    ShoulderCap(label: "RB", triangular: false, color: shoulderFill)
                }
            }
            .padding(.horizontal, landscape ? 40 : 48)
            .padding(.top, 6)

            Spacer(minLength: 8)

            // Main row: D-pad · GAME · face — equal spacing, no overlap
            HStack(alignment: .center, spacing: pad) {
                RefDPad()
                    .frame(width: sideCtrl, height: sideCtrl)

                gameScreen
                    .frame(width: gameW, height: gameH)

                RefFaceButtons(y: yColor, x: xColor, b: bColor, a: aColor, radius: faceR)
                    .frame(width: sideCtrl + 8, height: sideCtrl + 8)
            }
            .padding(.horizontal, pad)

            // Three dots under GAME
            HStack(spacing: 10) {
                holdDot(label: "−", id: InputBridge.SELECT)
                DotButton(
                    systemImage: "globe",
                    isActive: appState.showBrowserInPanel,
                    activeColor: .cyan
                ) {
                    haptic(.medium)
                    appState.toggleBrowserPanel()
                }
                holdDot(label: "+", id: InputBridge.START)
            }
            .padding(.top, 10)

            Spacer(minLength: 8)

            // Bottom: stick · Browser · stick
            HStack(alignment: .center, spacing: 12) {
                RefStick(offset: $leftStick, size: stickSize)

                browserPanel
                    .frame(maxWidth: .infinity)
                    .frame(height: browserH)

                RefStick(offset: $rightStick, size: stickSize)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            IconBtn("line.3.horizontal") {
                haptic(.light)
                appState.showInGameMenu = true
            }
            Text(game.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.55))
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

    // MARK: - GAME

    private var gameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)

            if hasLivePixels && showGamePanel {
                EmulatorScreenView()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(2)
            } else {
                Text("GAME")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Browser

    private var browserPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)

            if appState.showKeyboardInPanel {
                InPanelKeyboard()
            } else if appState.showBrowserInPanel {
                InPanelBrowser()
            } else {
                Button {
                    haptic(.medium)
                    appState.toggleBrowserPanel()
                } label: {
                    Text("Browser")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PressPopStyle())
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func holdDot(label: String, id: UInt32) -> some View {
        Text(label)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Circle().fill(Color.black.opacity(0.75)))
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in InputBridge.shared.set(id, pressed: true) }
                    .onEnded { _ in
                        InputBridge.shared.set(id, pressed: false)
                        haptic(.light)
                    }
            )
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Shoulders (reference shape)

struct ShoulderCap: View {
    let label: String
    let triangular: Bool
    let color: Color
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: triangular ? 52 : 56, height: triangular ? 20 : 22)
            .background(
                Group {
                    if triangular {
                        // Trapezoid-ish top shoulder
                        Capsule().fill(color)
                    } else {
                        RoundedRectangle(cornerRadius: 6).fill(color)
                    }
                }
            )
            .scaleEffect(pressed ? 0.92 : 1)
            .brightness(pressed ? -0.06 : 0)
            .animation(.spring(response: 0.16, dampingFraction: 0.65), value: pressed)
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

// MARK: - D-pad (reference plus)

struct RefDPad: View {
    @State private var glow = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Vertical bar
                RoundedRectangle(cornerRadius: s * 0.18)
                    .fill(Color.black)
                    .frame(width: s * 0.30, height: s)
                // Horizontal bar
                RoundedRectangle(cornerRadius: s * 0.18)
                    .fill(Color.black)
                    .frame(width: s, height: s * 0.30)
                // Center nub
                Circle()
                    .fill(Color.black)
                    .frame(width: s * 0.22, height: s * 0.22)
            }
            .frame(width: s, height: s)
            .shadow(color: glow ? Color.black.opacity(0.25) : .clear, radius: 6)
            .scaleEffect(glow ? 0.96 : 1)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: glow)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        glow = true
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
                        glow = false
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

// MARK: - Face buttons (reference diamond)

struct RefFaceButtons: View {
    let y: Color, x: Color, b: Color, a: Color
    var radius: CGFloat = 18

    var body: some View {
        let gap = radius * 2.15
        ZStack {
            face(y, "Y").offset(y: -gap)
            face(x, "X").offset(x: -gap)
            face(b, "B").offset(x: gap)
            face(a, "A").offset(y: gap)
        }
    }

    private func face(_ color: Color, _ label: String) -> some View {
        FaceButton(color: color, label: label, radius: radius)
    }
}

struct FaceButton: View {
    let color: Color
    let label: String
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
                    .shadow(color: color.opacity(pressed ? 0.55 : 0.25), radius: pressed ? 10 : 4, y: pressed ? 0 : 2)
            )
            .scaleEffect(pressed ? 0.88 : 1)
            .animation(.spring(response: 0.14, dampingFraction: 0.6), value: pressed)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            if let id = InputBridge.faceId(label) {
                                InputBridge.shared.set(id, pressed: true)
                            }
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        if let id = InputBridge.faceId(label) {
                            InputBridge.shared.set(id, pressed: false)
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            )
    }
}

// MARK: - Analog stick

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
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

            Circle()
                .fill(Color.black)
                .frame(width: knob, height: knob)
                .offset(offset)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
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

// MARK: - Shared chrome

struct DotButton: View {
    let systemImage: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(isActive ? activeColor.opacity(0.9) : Color.black.opacity(0.55))
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(isActive ? activeColor : .clear, lineWidth: 2)
                        .frame(width: 16, height: 16)
                )
                .shadow(color: isActive ? activeColor.opacity(0.5) : .clear, radius: 6)
        }
        .buttonStyle(PressPopStyle())
        .frame(width: 28, height: 28)
        .contentShape(Circle())
    }
}

struct PressPopStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.16, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Browser / keyboard

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

struct InPanelKeyboard: View {
    @EnvironmentObject var appState: AppState
    @State private var buffer = ""
    private let keys = ["1","2","3","4","Q","W","E","A","S","D","Z","X"]

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(buffer.isEmpty ? "type…" : buffer)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(buffer.isEmpty ? 0.4 : 0.9))
                    .lineLimit(1)
                Spacer()
                Button { appState.showKeyboardInPanel = false } label: {
                    Image(systemName: "xmark").font(.system(size: 9)).foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 6)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 4), spacing: 3) {
                ForEach(keys, id: \.self) { k in
                    Button {
                        buffer += k.lowercased()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(k)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(4)
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
                Toggle("Liquid Glass", isOn: $settings.useLiquidGlass)
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
