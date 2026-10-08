import SwiftUI
import UIKit

/// Exact layout from the reference image:
/// LT/LB · RT/RB on top, D-pad left, GAME center, YXBA right,
/// left stick · Browser · right stick on bottom.
/// Three dots under GAME are interactive: Cursor · Browser · Settings.
struct ControllerView: View {
    let game: GameItem
    var showGamePanel: Bool = true

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    @State private var leftStick: CGSize = .zero
    @State private var rightStick: CGSize = .zero
    @State private var showControllerSettings = false

    // Button colors from the photo
    private let yColor = Color(red: 1.0, green: 0.84, blue: 0.2)      // yellow
    private let xColor = Color(red: 0.35, green: 0.85, blue: 0.95)    // cyan
    private let bColor = Color(red: 0.95, green: 0.25, blue: 0.25)    // red
    private let aColor = Color(red: 0.25, green: 0.85, blue: 0.45)    // green
    private let shoulderColor = Color(red: 0.78, green: 0.82, blue: 0.88)

    var body: some View {
        ZStack {
            // Clean light background matching the photo, with subtle glass depth
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

            // Cursor mode active ring
            if appState.isMouseMode {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .padding(6)
                    .allowsHitTesting(false)
                    .shadow(color: .blue.opacity(0.45), radius: 12)
            }

            // Controller Settings glass modal (from the third dot)
            if showControllerSettings {
                ControllerSettingsModal(
                    isPresented: $showControllerSettings,
                    onQuit: {
                        showControllerSettings = false
                        appState.quitGame()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(50)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: showControllerSettings)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: appState.isMouseMode)
    }

    // MARK: - Exact photo layout
    private var photoLayout: some View {
        VStack(spacing: 0) {
            // Top bar: menu / TV / quit
            HStack {
                Button {
                    haptic(.light)
                    appState.showInGameMenu = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.45))
                        .frame(width: 36, height: 36)
                }
                Spacer()
                if settings.tvModeEnabled {
                    Button {
                        haptic(.medium)
                        appState.isTVModeActive.toggle()
                    } label: {
                        Image(systemName: appState.isTVModeActive ? "iphone" : "tv")
                            .font(.body)
                            .foregroundStyle(.black.opacity(0.45))
                    }
                }
                Button {
                    haptic(.medium)
                    appState.quitGame()
                } label: {
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
                    ShoulderPill(label: "LT", color: shoulderColor, isTrigger: true) { haptic(.soft) }
                    ShoulderPill(label: "LB", color: shoulderColor, isTrigger: false) { haptic(.light) }
                }
                Spacer()
                VStack(spacing: 6) {
                    ShoulderPill(label: "RT", color: shoulderColor, isTrigger: true) { haptic(.soft) }
                    ShoulderPill(label: "RB", color: shoulderColor, isTrigger: false) { haptic(.light) }
                }
            }
            .padding(.horizontal, 36)

            Spacer(minLength: 16)

            // —— MID: D-pad | GAME | YXBA ——
            HStack(alignment: .center, spacing: 12) {
                // D-pad
                PhotoDPad()
                    .frame(width: 88, height: 88)
                    .onTapGesture { haptic(.light) }

                // GAME screen (center black panel)
                gameScreen
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)

                // Face buttons diamond: Y top, X left, B right, A bottom
                PhotoFaceButtons(
                    y: yColor, x: xColor, b: bColor, a: aColor,
                    onPress: { haptic(.medium) }
                )
                .frame(width: 100, height: 100)
            }
            .padding(.horizontal, 16)

            // THREE INTERACTIVE DOTS under GAME (left → right)
            // 1. Cursor mode   2. Browser   3. Settings
            HStack(spacing: 22) {
                // 1. CURSOR / MOUSE MODE
                DotButton(
                    systemImage: "rectangle.on.rectangle",
                    isActive: appState.isMouseMode,
                    activeColor: .blue
                ) {
                    haptic(.medium)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        appState.isMouseMode.toggle()
                    }
                }

                // 2. BROWSER
                DotButton(
                    systemImage: "globe",
                    isActive: appState.isBrowserMode,
                    activeColor: .cyan
                ) {
                    haptic(.medium)
                    appState.isBrowserMode = true
                }

                // 3. SETTINGS
                DotButton(
                    systemImage: "gearshape.fill",
                    isActive: showControllerSettings,
                    activeColor: .purple
                ) {
                    haptic(.medium)
                    showControllerSettings = true
                }
            }
            .padding(.top, 12)

            Spacer(minLength: 18)

            // —— BOTTOM: Left stick | Browser panel | Right stick ——
            HStack(alignment: .center, spacing: 16) {
                PhotoStick(offset: $leftStick)
                    .frame(width: 86, height: 86)

                // Big Browser panel (quick-launch)
                Button {
                    haptic(.medium)
                    appState.isBrowserMode = true
                } label: {
                    Text("Browser")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black)
                                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                        )
                }
                .buttonStyle(PressDepthButtonStyle())

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
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            if showGamePanel {
                VStack(spacing: 6) {
                    Text("GAME")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(game.displaySystem)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))

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
        if let last = s.split(separator: "/").last { s = String(last) }
        s = s.replacingOccurrences(of: ".framework", with: "")
        s = s.replacingOccurrences(of: ".dylib", with: "")
        if s.lowercased().contains("libdns") { s = "libnds" }
        return s
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }
}

// MARK: - Interactive Dot Button

struct DotButton: View {
    let systemImage: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow ring when active
                if isActive {
                    Circle()
                        .stroke(activeColor.opacity(0.7), lineWidth: 2.5)
                        .frame(width: 28, height: 28)
                        .shadow(color: activeColor.opacity(0.55), radius: 6)
                }

                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isActive ? activeColor : Color.black.opacity(0.45))
                    .frame(width: 22, height: 22)
            }
            .frame(width: 32, height: 32)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Controller Settings Glass Modal

struct ControllerSettingsModal: View {
    @Binding var isPresented: Bool
    var onQuit: () -> Void

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var tweakStore: TweakStore

    @State private var section: SettingsSection = .tweaks

    enum SettingsSection: String, CaseIterable {
        case tweaks = "Tweaks"
        case keybinds = "Keybinds"
        case leave = "Leave"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.title3.bold())
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                // Section picker
                Picker("", selection: $section) {
                    ForEach(SettingsSection.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Divider().padding(.vertical, 10)

                Group {
                    switch section {
                    case .tweaks:
                        tweaksContent
                    case .keybinds:
                        keybindsContent
                    case .leave:
                        leaveContent
                    }
                }
                .frame(maxHeight: 300)
            }
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
            )
            .padding(28)
            .frame(maxWidth: 400)
        }
    }

    private var tweaksContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Video & Performance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                LabeledContent("Show FPS") {
                    Toggle("", isOn: $settings.showFPS)
                        .labelsHidden()
                }
                LabeledContent("Liquid Glass") {
                    Toggle("", isOn: $settings.useLiquidGlass)
                        .labelsHidden()
                }

                Text("Loaded Tweak")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Button("None") {
                    appState.loadedTweakName = nil
                }
                .buttonStyle(.bordered)

                ForEach(tweakStore.tweaks) { t in
                    Button {
                        appState.loadedTweakName = t.name
                    } label: {
                        HStack {
                            Text(t.name)
                            Spacer()
                            if appState.loadedTweakName == t.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    private var keybindsContent: some View {
        List {
            LabeledContent("D-Pad", value: "Touch / Arrows")
            LabeledContent("A / B / X / Y", value: "Face buttons")
            LabeledContent("L / R / LT / RT", value: "Shoulders")
            LabeledContent("Sticks", value: "Analog (dead-zone in Settings)")
            LabeledContent("Cursor Mode", value: "Left stick + A")
            Text("Full per-system remap editor coming soon.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var leaveContent: some View {
        VStack(spacing: 20) {
            Text("Save state and leave?")
                .font(.headline)
                .padding(.top)

            Button {
                // Placeholder for quick-save
                isPresented = false
            } label: {
                Label("Quick Save + Stay", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            Button {
                isPresented = false
                // Disconnect TV if active
                appState.isTVModeActive = false
            } label: {
                Label("Disconnect TV", systemImage: "tv.slash")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            Button(role: .destructive) {
                onQuit()
            } label: {
                Label("Quit Game", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Photo-matched components

struct ShoulderPill: View {
    let label: String
    let color: Color
    let isTrigger: Bool
    var onPress: (() -> Void)? = nil

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: isTrigger ? 52 : 56, height: isTrigger ? 22 : 26)
            .background(
                Group {
                    if isTrigger {
                        Capsule().fill(color)
                    } else {
                        RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture { onPress?() }
    }
}

struct PhotoDPad: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black)
                .frame(width: 28, height: 84)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black)
                .frame(width: 84, height: 28)
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
    var onPress: (() -> Void)? = nil

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
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(color))
            .shadow(color: color.opacity(0.4), radius: 4, y: 2)
            .contentShape(Circle())
            .onTapGesture { onPress?() }
    }
}

struct PhotoStick: View {
    @Binding var offset: CGSize
    private let maxTravel: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(white: 0.75), lineWidth: 8)
                .background(Circle().fill(Color(white: 0.92)))

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
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                offset = .zero
                            }
                        }
                )
        }
    }
}

// Subtle press-depth style for the Browser panel
struct PressDepthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
