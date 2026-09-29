import SwiftUI

/// showGamePanel true  = ON PHONE MODE (game + controls)
/// showGamePanel false = ON TV MODE (controller only)
struct ControllerView: View {
    let game: GameItem
    var showGamePanel: Bool = true

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    @State private var leftStick: CGSize = .zero
    @State private var rightStick: CGSize = .zero

    var body: some View {
        ZStack {
            settings.joystickColor.ignoresSafeArea()

            if appState.isBrowserMode {
                BrowserModeView()
            } else if showGamePanel {
                onPhoneLayout
            } else {
                onTVLayout
            }

            VStack {
                HStack {
                    Spacer()
                    FPSOverlay()
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                }
                Spacer()
            }

            if appState.isMouseMode {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.blue, lineWidth: 4)
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var onPhoneLayout: some View {
        VStack(spacing: 0) {
            topBar

            HStack(alignment: .center, spacing: 6) {
                VStack(spacing: 16) {
                    DPadView(accent: settings.joystickAccent).scaleEffect(0.9)
                    AnalogStickView(offset: $leftStick, accent: settings.joystickAccent).scaleEffect(0.85)
                }
                .frame(width: 110)

                gamePanel
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        FaceButton(label: "Y", color: .yellow, size: 40)
                        FaceButton(label: "X", color: .blue, size: 40)
                    }
                    HStack(spacing: 10) {
                        FaceButton(label: "B", color: .red, size: 40)
                        FaceButton(label: "A", color: .green, size: 40)
                    }
                    AnalogStickView(offset: $rightStick, accent: settings.joystickAccent).scaleEffect(0.75)
                    HStack(spacing: 8) {
                        TriggerButton(label: "L")
                        TriggerButton(label: "R")
                    }
                }
                .frame(width: 110)
            }
            .padding(.horizontal, 6)

            Spacer(minLength: 8)

            HStack {
                ControllerButton(systemName: "minus", size: 32) {}
                Spacer()
                Text(game.name)
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                Spacer()
                ControllerButton(systemName: "plus", size: 32) {}
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private var onTVLayout: some View {
        VStack(spacing: 0) {
            topBar
            Text("TV MODE — game on external display")
                .font(.caption2)
                .foregroundStyle(settings.joystickAccent)
                .padding(.top, 4)
            Spacer()
            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 22) {
                    DPadView(accent: settings.joystickAccent)
                    AnalogStickView(offset: $leftStick, accent: settings.joystickAccent)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 14) {
                    HStack(spacing: 16) {
                        FaceButton(label: "Y", color: .yellow, size: 52)
                        FaceButton(label: "X", color: .blue, size: 52)
                    }
                    HStack(spacing: 16) {
                        FaceButton(label: "B", color: .red, size: 52)
                        FaceButton(label: "A", color: .green, size: 52)
                    }
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 22) {
                    AnalogStickView(offset: $rightStick, accent: settings.joystickAccent)
                    HStack(spacing: 12) {
                        TriggerButton(label: "LT")
                        TriggerButton(label: "RT")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
            HStack {
                ControllerButton(systemName: "minus", size: 34) {}
                Spacer()
                Text(appState.isMouseMode ? "MOUSE" : "CONTROLLER")
                    .font(.caption2.bold())
                    .foregroundStyle(settings.joystickAccent)
                Spacer()
                ControllerButton(systemName: "plus", size: 34) {}
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 20)
        }
    }

    private var gamePanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(settings.joystickAccent.opacity(0.4), lineWidth: 1.5)

            VStack(spacing: 6) {
                Image(systemName: "rectangle.split.2x1.fill")
                    .font(.title)
                    .foregroundStyle(settings.accentColor.opacity(0.85))
                Text("Emulated Game")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
                Text(game.name)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                // Core status from dylib loader
                Text(appState.coreStatus)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(
                        CoreLoader.shared.loadedCoreName != nil
                        ? Color.green.opacity(0.9)
                        : Color.orange.opacity(0.9)
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
        }
    }

    private var topBar: some View {
        HStack {
            ControllerButton(systemName: "line.3.horizontal", size: 40) {
                appState.showInGameMenu = true
            }
            Spacer()
            HStack(spacing: 8) {
                ControllerButton(systemName: "rectangle.on.rectangle", size: 36) {
                    appState.isMouseMode.toggle()
                }
                ControllerButton(systemName: "rectangle.on.rectangle", size: 36) {
                    appState.isMouseMode.toggle()
                }
            }
            Spacer()
            Button {
                appState.isBrowserMode.toggle()
            } label: {
                ZStack {
                    Circle().fill(settings.joystickAccent.opacity(0.25)).frame(width: 40, height: 40)
                    Image(systemName: "safari.fill").font(.body).foregroundStyle(settings.joystickAccent)
                }
            }
            if settings.tvModeEnabled {
                ControllerButton(systemName: appState.isTVModeActive ? "iphone" : "tv", size: 36) {
                    appState.isTVModeActive.toggle()
                }
            }
            ControllerButton(systemName: "xmark", size: 36) {
                appState.quitGame()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }
}

struct ControllerButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.4))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.white.opacity(0.08)).shadow(color: .black.opacity(0.4), radius: 3, y: 2))
                .overlay(Circle().stroke(settings.joystickAccent.opacity(0.4), lineWidth: 1.2))
        }
    }
}

struct FaceButton: View {
    let label: String
    let color: Color
    var size: CGFloat = 52

    var body: some View {
        Text(label)
            .font(.system(size: size * 0.35, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(color.opacity(0.85)).shadow(color: color.opacity(0.45), radius: 5, y: 2))
    }
}

struct TriggerButton: View {
    let label: String
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .frame(width: 44, height: 24)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(settings.joystickAccent.opacity(0.3)))
    }
}

struct DPadView: View {
    let accent: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.14)).frame(width: 32, height: 96)
            RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.14)).frame(width: 96, height: 32)
            Circle().fill(accent.opacity(0.35)).frame(width: 24, height: 24)
        }
    }
}

struct AnalogStickView: View {
    @Binding var offset: CGSize
    let accent: Color
    private let maxTravel: CGFloat = 30

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.1)).frame(width: 88, height: 88)
            Circle()
                .fill(LinearGradient(colors: [accent.opacity(0.85), accent.opacity(0.4)], startPoint: .top, endPoint: .bottom))
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
                            withAnimation(.spring(response: 0.25)) { offset = .zero }
                        }
                )
                .shadow(color: accent.opacity(0.45), radius: 6)
        }
    }
}
