import SwiftUI
import UIKit

/// Horizontal liquid-glass controller layout.
/// Landscape-friendly: left stick+D-pad | GAME + dots | face+right stick.
struct ControllerView: View {
    let game: GameItem
    var showGamePanel: Bool = true

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    @State private var leftStick: CGSize = .zero
    @State private var rightStick: CGSize = .zero
    @State private var showControllerSettings = false

    private let yColor = Color(red: 1.0, green: 0.84, blue: 0.2)
    private let xColor = Color(red: 0.35, green: 0.85, blue: 0.95)
    private let bColor = Color(red: 0.95, green: 0.25, blue: 0.25)
    private let aColor = Color(red: 0.25, green: 0.85, blue: 0.45)
    private let shoulderColor = Color(red: 0.78, green: 0.82, blue: 0.88)

    var body: some View {
        ZStack {
            // Soft gradient base under glass
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.94, blue: 0.98),
                    Color(red: 0.86, green: 0.89, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if appState.isBrowserMode {
                BrowserModeView()
            } else {
                horizontalGlassLayout
            }

            VStack {
                HStack {
                    Spacer()
                    FPSOverlay()
                        .padding(.trailing, 14)
                        .padding(.top, 8)
                }
                Spacer()
            }

            if appState.isMouseMode {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3.5
                    )
                    .padding(8)
                    .allowsHitTesting(false)
                    .shadow(color: .blue.opacity(0.4), radius: 14)
            }

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

    // MARK: - Horizontal liquid-glass layout

    private var horizontalGlassLayout: some View {
        VStack(spacing: 10) {
            // Top chrome
            HStack {
                glassIconButton("line.3.horizontal") {
                    haptic(.light)
                    appState.showInGameMenu = true
                }
                Spacer()
                Text(game.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.55))
                    .lineLimit(1)
                Spacer()
                if settings.tvModeEnabled {
                    glassIconButton(appState.isTVModeActive ? "iphone" : "tv") {
                        haptic(.medium)
                        appState.isTVModeActive.toggle()
                    }
                }
                glassIconButton("xmark") {
                    haptic(.medium)
                    appState.quitGame()
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)

            // Shoulders row
            HStack {
                HStack(spacing: 8) {
                    ShoulderPill(label: "LT", color: shoulderColor, isTrigger: true) { haptic(.soft) }
                    ShoulderPill(label: "LB", color: shoulderColor, isTrigger: false) { haptic(.light) }
                }
                Spacer()
                HStack(spacing: 8) {
                    ShoulderPill(label: "RB", color: shoulderColor, isTrigger: false) { haptic(.light) }
                    ShoulderPill(label: "RT", color: shoulderColor, isTrigger: true) { haptic(.soft) }
                }
            }
            .padding(.horizontal, 20)

            // MAIN HORIZONTAL STRIP
            HStack(alignment: .center, spacing: 10) {
                // LEFT glass panel: stick + D-pad
                VStack(spacing: 14) {
                    PhotoStick(offset: $leftStick)
                        .frame(width: 78, height: 78)
                    PhotoDPad()
                        .frame(width: 80, height: 80)
                        .onTapGesture { haptic(.light) }
                }
                .padding(14)
                .background(glassCard)

                // CENTER: GAME + horizontal dots + Browser
                VStack(spacing: 10) {
                    gameScreen
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)

                    // Dots in a horizontal glass pill
                    HStack(spacing: 20) {
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
                        DotButton(
                            systemImage: "globe",
                            isActive: appState.isBrowserMode,
                            activeColor: .cyan
                        ) {
                            haptic(.medium)
                            appState.isBrowserMode = true
                        }
                        DotButton(
                            systemImage: "gearshape.fill",
                            isActive: showControllerSettings,
                            activeColor: .purple
                        ) {
                            haptic(.medium)
                            showControllerSettings = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(glassCard)

                    Button {
                        haptic(.medium)
                        appState.isBrowserMode = true
                    } label: {
                        Text("Browser")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.black.opacity(0.88))
                            )
                    }
                    .buttonStyle(PressDepthButtonStyle())
                }
                .frame(maxWidth: .infinity)

                // RIGHT glass panel: face buttons + stick
                VStack(spacing: 14) {
                    PhotoFaceButtons(
                        y: yColor, x: xColor, b: bColor, a: aColor,
                        onPress: { haptic(.medium) }
                    )
                    .frame(width: 92, height: 92)

                    PhotoStick(offset: $rightStick)
                        .frame(width: 78, height: 78)
                }
                .padding(14)
                .background(glassCard)
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 4)

            // Status strip
            HStack(spacing: 8) {
                statusChip(appState.coreStatus, color: CoreLoader.shared.loadedCoreName != nil ? .green : .orange)
                if !appState.romLoadStatus.isEmpty {
                    statusChip(appState.romLoadStatus, color: .cyan)
                }
            }
            .padding(.bottom, 10)
        }
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    private func glassIconButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.body.weight(.semibold))
                .foregroundStyle(.black.opacity(0.5))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private func statusChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .lineLimit(1)
    }

    private var gameScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            if showGamePanel {
                VStack(spacing: 5) {
                    Text("GAME")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(game.displaySystem)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                    if let name = CoreLoader.shared.loadedCoreName {
                        Text(cleanCoreName(name))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.green.opacity(0.9))
                    } else {
                        Text("No core — add .dylib to Cores/")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.orange.opacity(0.9))
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
        return s
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
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
            ZStack {
                if isActive {
                    Circle()
                        .stroke(activeColor.opacity(0.75), lineWidth: 2.5)
                        .frame(width: 28, height: 28)
                        .shadow(color: activeColor.opacity(0.5), radius: 6)
                }
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isActive ? activeColor : Color.black.opacity(0.45))
                    .frame(width: 22, height: 22)
            }
            .frame(width: 32, height: 32)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

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
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                HStack {
                    Text("Settings").font(.title3.bold())
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2).foregroundStyle(.secondary)
                    }
                }
                .padding()

                Picker("", selection: $section) {
                    ForEach(SettingsSection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Divider().padding(.vertical, 10)

                Group {
                    switch section {
                    case .tweaks: tweaksContent
                    case .keybinds: keybindsContent
                    case .leave: leaveContent
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
            VStack(alignment: .leading, spacing: 14) {
                LabeledContent("Show FPS") {
                    Toggle("", isOn: $settings.showFPS).labelsHidden()
                }
                LabeledContent("Liquid Glass") {
                    Toggle("", isOn: $settings.useLiquidGlass).labelsHidden()
                }
                Text("Tweaks").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Button("None") { appState.loadedTweakName = nil }.buttonStyle(.bordered)
                ForEach(tweakStore.tweaks) { t in
                    Button {
                        appState.loadedTweakName = t.name
                    } label: {
                        HStack {
                            Text(t.name)
                            Spacer()
                            if appState.loadedTweakName == t.name {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
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
            LabeledContent("D-Pad", value: "Touch")
            LabeledContent("Face buttons", value: "A B X Y")
            LabeledContent("Shoulders", value: "L R LT RT")
            LabeledContent("Sticks", value: "Analog")
            LabeledContent("Cursor", value: "Left stick + A")
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var leaveContent: some View {
        VStack(spacing: 16) {
            Button {
                isPresented = false
                appState.isTVModeActive = false
            } label: {
                Label("Disconnect TV", systemImage: "tv.slash")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.orange.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            Button(role: .destructive) { onQuit() } label: {
                Label("Quit Game", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding()
    }
}

struct ShoulderPill: View {
    let label: String
    let color: Color
    let isTrigger: Bool
    var onPress: (() -> Void)? = nil

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.3))
            .frame(width: isTrigger ? 50 : 54, height: isTrigger ? 22 : 26)
            .background(
                Group {
                    if isTrigger { Capsule().fill(color) }
                    else { RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color) }
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
                .fill(Color.black).frame(width: 26, height: 78)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black).frame(width: 78, height: 26)
            Circle().fill(Color.black).frame(width: 20, height: 20)
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
            face(y, "Y").offset(y: -30)
            face(x, "X").offset(x: -30)
            face(b, "B").offset(x: 30)
            face(a, "A").offset(y: 30)
        }
    }

    private func face(_ color: Color, _ label: String) -> some View {
        Text(label)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Circle().fill(color))
            .shadow(color: color.opacity(0.4), radius: 3, y: 1)
            .contentShape(Circle())
            .onTapGesture { onPress?() }
    }
}

struct PhotoStick: View {
    @Binding var offset: CGSize
    private let maxTravel: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(white: 0.72), lineWidth: 7)
                .background(Circle().fill(Color(white: 0.9)))
            Circle()
                .fill(Color.black)
                .frame(width: 48, height: 48)
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

struct PressDepthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
