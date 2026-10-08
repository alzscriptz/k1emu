import SwiftUI
import UIKit
import WebKit

/// Exact layout from reference: LT/LB · RT/RB, D-pad · GAME · YXBA,
/// three dots, stick · Browser · stick.
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

    private var photoLayout: some View {
        VStack(spacing: 0) {
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
            .padding(.top, 4)

            Spacer(minLength: 4)

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

            Spacer(minLength: 8)

            HStack(alignment: .center, spacing: 8) {
                PhotoDPad()
                    .frame(width: 78, height: 78)
                    .onTapGesture { haptic(.light) }

                gameScreen
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)

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
                .frame(width: 90, height: 90)
            }
            .padding(.horizontal, 12)

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
            .padding(.top, 8)

            Spacer(minLength: 10)

            // Larger Browser on the side (center panel bigger)
            HStack(alignment: .center, spacing: 10) {
                PhotoStick(offset: $leftStick)
                    .frame(width: 72, height: 72)

                browserPanel
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)

                PhotoStick(offset: $rightStick)
                    .frame(width: 72, height: 72)
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                statusChip(appState.coreStatus,
                           color: (appState.usingBuiltinCore || core.loadedCoreName != nil) ? .green : .orange)
                if !appState.romLoadStatus.isEmpty {
                    statusChip(appState.romLoadStatus, color: .cyan)
                }
                if hasLivePixels {
                    statusChip("\(fb.width)x\(fb.height)", color: .green)
                }
            }
            .padding(.bottom, 10)
        }
    }

    private var gameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black)

            if hasLivePixels {
                EmulatorScreenView()
                    .padding(2)
            } else {
                VStack(spacing: 4) {
                    Text("GAME")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(game.displaySystem)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    if let name = core.loadedCoreName {
                        Text(name)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.green.opacity(0.9))
                        if core.isRunning {
                            Text("waiting for frames…")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow.opacity(0.8))
                        }
                    } else if !appState.romLoadStatus.isEmpty {
                        Text(appState.romLoadStatus)
                            .font(.system(size: 8))
                            .foregroundStyle(.orange.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 6)
                    }
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

    private func shoulderTrapezoid(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: 48, height: 18)
            .background(Capsule().fill(shoulderColor))
            .onTapGesture { haptic(.soft) }
    }

    private func shoulderPill(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: 52, height: 22)
            .background(RoundedRectangle(cornerRadius: 5).fill(shoulderColor))
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
