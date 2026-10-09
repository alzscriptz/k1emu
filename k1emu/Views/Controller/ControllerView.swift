import SwiftUI
import UIKit
import WebKit

/// Controller layout: LT/LB · RT/RB, D-pad · GAME · YXBA,
/// three dots, stick · Browser · stick. GAME takes most vertical space.
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
    @State private var showControllerSettings = false

    private let yColor = Color(red: 1.0, green: 0.84, blue: 0.2)
    private let xColor = Color(red: 0.35, green: 0.85, blue: 0.95)
    private let bColor = Color(red: 0.95, green: 0.25, blue: 0.25)
    private let aColor = Color(red: 0.25, green: 0.85, blue: 0.45)
    private let shoulderColor = Color(red: 0.78, green: 0.82, blue: 0.88)

    private var hasLivePixels: Bool {
        (appState.usingBuiltinCore && chip8.isRunning) || (core.isRunning && fb.width > 0)
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            GeometryReader { geo in
                photoLayout(height: geo.size.height, width: geo.size.width)
            }

            if appState.isMouseMode {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.8), lineWidth: 3)
                    .padding(8)
                    .allowsHitTesting(false)
            }

            if showControllerSettings {
                ControllerSettingsModal(
                    isPresented: $showControllerSettings,
                    onQuit: {
                        showControllerSettings = false
                        appState.quitGame()
                    }
                )
                .zIndex(50)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onDisappear { InputBridge.shared.clearAll() }
    }

    private func photoLayout(height: CGFloat, width: CGFloat) -> some View {
        // GAME gets ~48% of screen height so NDS dual-screen fills the panel
        let gameH = max(220, height * 0.48)
        let browserH: CGFloat = 72

        return VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    haptic(.light)
                    appState.showInGameMenu = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.black.opacity(0.4))
                        .frame(width: 36, height: 36)
                }
                Spacer()
                Text(game.name)
                    .font(.caption2)
                    .foregroundStyle(.black.opacity(0.35))
                    .lineLimit(1)
                Spacer()
                Button {
                    haptic(.medium)
                    appState.isTVModeActive = true
                } label: {
                    Image(systemName: "tv")
                        .foregroundStyle(.black.opacity(0.4))
                        .frame(width: 36, height: 36)
                }
                Button {
                    haptic(.medium)
                    appState.quitGame()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black.opacity(0.4))
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 2)

            // Shoulders
            HStack {
                VStack(spacing: 4) {
                    shoulderButton("LT")
                    shoulderButton("LB")
                }
                Spacer()
                VStack(spacing: 4) {
                    shoulderButton("RT")
                    shoulderButton("RB")
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 4)

            // GAME row — large
            HStack(alignment: .center, spacing: 4) {
                PhotoDPad()
                    .frame(width: 88, height: 88)

                gameScreen
                    .frame(maxWidth: .infinity)
                    .frame(height: gameH)

                PhotoFaceButtons(y: yColor, x: xColor, b: bColor, a: aColor)
                    .frame(width: 100, height: 100)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Dots: Select · Browser toggle · Start
            HStack(spacing: 22) {
                holdDot(label: "−", id: InputBridge.SELECT)
                DotButton(systemImage: "globe",
                          isActive: appState.showBrowserInPanel, activeColor: .cyan) {
                    haptic(.medium)
                    appState.toggleBrowserPanel()
                }
                holdDot(label: "+", id: InputBridge.START)
            }
            .padding(.top, 8)

            Spacer(minLength: 4)

            // Sticks + Browser
            HStack(alignment: .center, spacing: 8) {
                PhotoStick(offset: $leftStick)
                    .frame(width: 68, height: 68)

                browserPanel
                    .frame(maxWidth: .infinity)
                    .frame(height: browserH)

                PhotoStick(offset: $rightStick)
                    .frame(width: 68, height: 68)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .frame(width: width, height: height)
    }

    private var gameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black)

            if hasLivePixels {
                EmulatorScreenView()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(3)
            } else {
                VStack(spacing: 4) {
                    Text("GAME")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(game.displaySystem)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    private var browserPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black)

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
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PressDepthButtonStyle())
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func shoulderButton(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: label.hasSuffix("T") ? 48 : 52, height: label.hasSuffix("T") ? 18 : 22)
            .background(
                Group {
                    if label.hasSuffix("T") {
                        Capsule().fill(shoulderColor)
                    } else {
                        RoundedRectangle(cornerRadius: 5).fill(shoulderColor)
                    }
                }
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if let id = InputBridge.shoulderId(label) {
                            InputBridge.shared.set(id, pressed: true)
                        }
                    }
                    .onEnded { _ in
                        if let id = InputBridge.shoulderId(label) {
                            InputBridge.shared.set(id, pressed: false)
                        }
                        haptic(.soft)
                    }
            )
    }

    private func holdDot(label: String, id: UInt32) -> some View {
        Text(label)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Circle().fill(Color.black.opacity(0.7)))
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

// MARK: - In-panel Browser

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
                .overlay(Circle().stroke(isActive ? activeColor : .clear, lineWidth: 2).frame(width: 16, height: 16))
        }
        .buttonStyle(.plain)
        .frame(width: 28, height: 28)
        .contentShape(Circle())
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

struct PhotoDPad: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 5).fill(Color.black).frame(width: s * 0.32, height: s)
                RoundedRectangle(cornerRadius: 5).fill(Color.black).frame(width: s, height: s * 0.32)
                Circle().fill(Color.black).frame(width: s * 0.24, height: s * 0.24)
            }
            .frame(width: s, height: s)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let c = CGPoint(x: s / 2, y: s / 2)
                        let dx = v.location.x - c.x
                        let dy = v.location.y - c.y
                        let dead: CGFloat = 8
                        let ib = InputBridge.shared
                        ib.set(InputBridge.UP, pressed: dy < -dead)
                        ib.set(InputBridge.DOWN, pressed: dy > dead)
                        ib.set(InputBridge.LEFT, pressed: dx < -dead)
                        ib.set(InputBridge.RIGHT, pressed: dx > dead)
                    }
                    .onEnded { _ in
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

struct PhotoFaceButtons: View {
    let y: Color, x: Color, b: Color, a: Color

    var body: some View {
        ZStack {
            face(y, "Y").offset(y: -32)
            face(x, "X").offset(x: -32)
            face(b, "B").offset(x: 32)
            face(a, "A").offset(y: 32)
        }
    }

    private func face(_ color: Color, _ label: String) -> some View {
        Text(label)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(color))
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if let id = InputBridge.faceId(label) {
                            InputBridge.shared.set(id, pressed: true)
                        }
                    }
                    .onEnded { _ in
                        if let id = InputBridge.faceId(label) {
                            InputBridge.shared.set(id, pressed: false)
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            )
    }
}

struct PhotoStick: View {
    @Binding var offset: CGSize
    private let maxTravel: CGFloat = 18
    var body: some View {
        ZStack {
            Circle().stroke(Color(white: 0.7), lineWidth: 8).background(Circle().fill(Color(white: 0.9)))
            Circle().fill(Color.black).frame(width: 46, height: 46).offset(offset)
                .gesture(DragGesture()
                    .onChanged { v in
                        offset = CGSize(
                            width: max(-maxTravel, min(maxTravel, v.translation.width)),
                            height: max(-maxTravel, min(maxTravel, v.translation.height))
                        )
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) { offset = .zero }
                    })
        }
    }
}

struct PressDepthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
