import SwiftUI
import UIKit
import WebKit

/// Exact layout from reference: LT/LB · RT/RB, D-pad · GAME · YXBA,
/// three dots, stick · Browser · stick. Browser/keyboard stay IN the Browser panel.
struct ControllerView: View {
    let game: GameItem
    var showGamePanel: Bool = true

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject private var chip8 = Chip8Core.shared

    @State private var leftStick: CGSize = .zero
    @State private var rightStick: CGSize = .zero
    @State private var showControllerSettings = false

    private let yColor = Color(red: 1.0, green: 0.84, blue: 0.2)
    private let xColor = Color(red: 0.35, green: 0.85, blue: 0.95)
    private let bColor = Color(red: 0.95, green: 0.25, blue: 0.25)
    private let aColor = Color(red: 0.25, green: 0.85, blue: 0.45)
    private let shoulderColor = Color(red: 0.78, green: 0.82, blue: 0.88)

    /// Effective: hide game when TV sharing
    private var gameVisible: Bool {
        showGamePanel && !appState.isTVModeActive
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            photoLayout

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
    }

    // MARK: - Photo layout (matches GAME.jpg)

    private var photoLayout: some View {
        VStack(spacing: 0) {
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
                    appState.isTVModeActive.toggle()
                } label: {
                    Image(systemName: appState.isTVModeActive ? "iphone" : "tv")
                        .foregroundStyle(appState.isTVModeActive ? .blue : .black.opacity(0.4))
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
            .padding(.top, 4)

            Spacer(minLength: 6)

            // SHOULDERS: LT/LB ····· RT/RB
            HStack {
                VStack(spacing: 5) {
                    shoulderTrapezoid("LT")
                    shoulderPill("LB")
                }
                Spacer()
                VStack(spacing: 5) {
                    shoulderTrapezoid("RT")
                    shoulderPill("RB")
                }
            }
            .padding(.horizontal, 40)

            Spacer(minLength: 12)

            // MID: D-pad | GAME | YXBA
            HStack(alignment: .center, spacing: 10) {
                PhotoDPad()
                    .frame(width: 84, height: 84)
                    .onTapGesture { haptic(.light) }

                gameScreen
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)

                PhotoFaceButtons(y: yColor, x: xColor, b: bColor, a: aColor) { key in
                    haptic(.medium)
                    if appState.usingBuiltinCore {
                        let map: [String: Int] = ["A": 5, "B": 6, "X": 4, "Y": 1]
                        if let k = map[key] {
                            chip8.setKey(k, pressed: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                chip8.setKey(k, pressed: false)
                            }
                        }
                    }
                }
                .frame(width: 96, height: 96)
            }
            .padding(.horizontal, 14)

            // THREE DOTS under GAME
            HStack(spacing: 18) {
                DotButton(systemImage: "rectangle.on.rectangle",
                          isActive: appState.isMouseMode, activeColor: .blue) {
                    haptic(.medium)
                    appState.isMouseMode.toggle()
                }
                DotButton(systemImage: "globe",
                          isActive: appState.showBrowserInPanel, activeColor: .cyan) {
                    haptic(.medium)
                    appState.toggleBrowserPanel()
                }
                DotButton(systemImage: "keyboard",
                          isActive: appState.showKeyboardInPanel, activeColor: .orange) {
                    haptic(.medium)
                    appState.toggleKeyboardPanel()
                }
            }
            .padding(.top, 10)

            Spacer(minLength: 14)

            // BOTTOM: stick | Browser panel | stick
            HStack(alignment: .center, spacing: 14) {
                PhotoStick(offset: $leftStick)
                    .frame(width: 82, height: 82)

                browserPanel
                    .frame(width: 130, height: 72)

                PhotoStick(offset: $rightStick)
                    .frame(width: 82, height: 82)
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 10)

            // Status
            HStack(spacing: 6) {
                statusChip(appState.coreStatus,
                           color: (appState.usingBuiltinCore || CoreLoader.shared.loadedCoreName != nil) ? .green : .orange)
                if !appState.romLoadStatus.isEmpty {
                    statusChip(appState.romLoadStatus, color: .cyan)
                }
                if appState.isTVModeActive {
                    statusChip("TV", color: .blue)
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - GAME screen

    private var gameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black)

            if !gameVisible {
                // TV share: phone is controller only — no game pixels here
                VStack(spacing: 4) {
                    Image(systemName: "tv")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("TV MODE")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("Game on external display")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
            } else if appState.usingBuiltinCore && chip8.isRunning {
                EmulatorScreenView()
                    .padding(3)
            } else {
                VStack(spacing: 4) {
                    Text("GAME")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(game.displaySystem)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    if let name = CoreLoader.shared.loadedCoreName {
                        Text(name)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.green.opacity(0.9))
                    } else if !appState.romLoadStatus.isEmpty {
                        Text(appState.romLoadStatus)
                            .font(.system(size: 8))
                            .foregroundStyle(.orange.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 6)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    // MARK: - Browser panel (in-place, not another window)

    private var browserPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black)

            if appState.showKeyboardInPanel {
                // Keyboard for games that need text input
                InPanelKeyboard()
            } else if appState.showBrowserInPanel {
                // Web browser embedded in the panel
                InPanelBrowser()
            } else {
                Button {
                    haptic(.medium)
                    appState.toggleBrowserPanel()
                } label: {
                    Text("Browser")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PressDepthButtonStyle())
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Helpers

    private func shoulderTrapezoid(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: 48, height: 18)
            .background(
                Capsule().fill(shoulderColor)
            )
            .onTapGesture { haptic(.soft) }
    }

    private func shoulderPill(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: 52, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 5).fill(shoulderColor)
            )
            .onTapGesture { haptic(.light) }
    }

    private func statusChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
            .lineLimit(1)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - In-panel Browser (stays in Browser rectangle)

struct InPanelBrowser: View {
    @EnvironmentObject var appState: AppState
    @State private var url = URL(string: "https://search.brave.com")!

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MiniWebView(url: $url)
            Button {
                appState.showBrowserInPanel = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(4)
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
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

// MARK: - In-panel Keyboard

struct InPanelKeyboard: View {
    @EnvironmentObject var appState: AppState
    @State private var buffer = ""

    private let keys = ["1","2","3","4","Q","W","E","A","S","D","Z","X"]

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(buffer.isEmpty ? "type…" : buffer)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(buffer.isEmpty ? 0.4 : 0.9))
                    .lineLimit(1)
                Spacer()
                Button {
                    appState.showKeyboardInPanel = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4), spacing: 2) {
                ForEach(keys, id: \.self) { k in
                    Button {
                        buffer += k.lowercased()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(k)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 3)
        }
        .padding(3)
    }
}

// MARK: - Shared components

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
        }
        .buttonStyle(.plain)
        .frame(width: 28, height: 28)
        .contentShape(Circle())
    }
}

struct ControllerSettingsModal: View {
    @Binding var isPresented: Bool
    var onQuit: () -> Void
    @EnvironmentObject var appState: AppState
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
        ZStack {
            RoundedRectangle(cornerRadius: 5).fill(Color.black).frame(width: 24, height: 76)
            RoundedRectangle(cornerRadius: 5).fill(Color.black).frame(width: 76, height: 24)
            Circle().fill(Color.black).frame(width: 18, height: 18)
        }
    }
}

struct PhotoFaceButtons: View {
    let y: Color, x: Color, b: Color, a: Color
    var onPress: ((String) -> Void)? = nil

    var body: some View {
        ZStack {
            face(y, "Y").offset(y: -28)
            face(x, "X").offset(x: -28)
            face(b, "B").offset(x: 28)
            face(a, "A").offset(y: 28)
        }
    }

    private func face(_ color: Color, _ label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(Circle().fill(color))
            .contentShape(Circle())
            .onTapGesture { onPress?(label) }
    }
}

struct PhotoStick: View {
    @Binding var offset: CGSize
    private let maxTravel: CGFloat = 18

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(white: 0.7), lineWidth: 8)
                .background(Circle().fill(Color(white: 0.9)))
            Circle()
                .fill(Color.black)
                .frame(width: 46, height: 46)
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
    }
}

struct PressDepthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
