import SwiftUI

/// Full Xbox-style controller layout used when phone is the controller (TV / external display mode).
struct ControllerView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    @State private var leftStick: CGSize = .zero
    @State private var rightStick: CGSize = .zero

    var body: some View {
        ZStack {
            settings.joystickColor.ignoresSafeArea()

            // Browser mode overlay takes over the whole controller screen
            if appState.isBrowserMode {
                BrowserModeView()
            } else {
                controllerLayout
            }

            // Blue Xbox-style outline when mouse mode is active
            if appState.isMouseMode {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.blue, lineWidth: 4)
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var controllerLayout: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top bar: Menu | Windows | Windows | Browser button
                HStack {
                    // Menu button
                    ControllerButton(systemName: "line.3.horizontal", size: 44) {
                        appState.showInGameMenu = true
                        // also ensure outline if needed
                    }

                    Spacer()

                    // Two Windows buttons (mouse mode toggle)
                    HStack(spacing: 12) {
                        ControllerButton(systemName: "rectangle.on.rectangle", size: 40) {
                            toggleMouseMode()
                        }
                        ControllerButton(systemName: "rectangle.on.rectangle", size: 40) {
                            toggleMouseMode()
                        }
                    }

                    Spacer()

                    // Browser mode button (cool picture)
                    Button {
                        appState.isBrowserMode.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(settings.joystickAccent.opacity(0.25))
                                .frame(width: 48, height: 48)
                            Image(systemName: "safari.fill")
                                .font(.title2)
                                .foregroundStyle(settings.joystickAccent)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                // Main controls row
                HStack(alignment: .center, spacing: 0) {
                    // Left side: D-Pad + Left Stick
                    VStack(spacing: 28) {
                        DPadView(accent: settings.joystickAccent)
                        AnalogStickView(offset: $leftStick, accent: settings.joystickAccent)
                    }
                    .frame(maxWidth: .infinity)

                    // Center face buttons (A B X Y style)
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            FaceButton(label: "Y", color: .yellow)
                            FaceButton(label: "X", color: .blue)
                        }
                        HStack(spacing: 20) {
                            FaceButton(label: "B", color: .red)
                            FaceButton(label: "A", color: .green)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right side: Right Stick + triggers hint
                    VStack(spacing: 28) {
                        AnalogStickView(offset: $rightStick, accent: settings.joystickAccent)
                        HStack(spacing: 16) {
                            TriggerButton(label: "LT")
                            TriggerButton(label: "RT")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 12)

                Spacer()

                // Bottom: Select / Start + game name
                HStack {
                    ControllerButton(systemName: "minus", size: 36) {}
                    Spacer()
                    VStack(spacing: 2) {
                        Text(game.name)
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.9))
                        Text(appState.isMouseMode ? "MOUSE MODE" : "CONTROLLER")
                            .font(.caption2)
                            .foregroundStyle(settings.joystickAccent)
                    }
                    Spacer()
                    ControllerButton(systemName: "plus", size: 36) {}
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }

    private func toggleMouseMode() {
        appState.isMouseMode.toggle()
    }
}

// MARK: - Controller sub-components

struct ControllerButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.45))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(settings.joystickColor)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                )
                .overlay(
                    Circle()
                        .stroke(settings.joystickAccent.opacity(0.5), lineWidth: 1.5)
                )
        }
    }
}

struct FaceButton: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.title2.bold())
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(color.opacity(0.85))
                    .shadow(color: color.opacity(0.5), radius: 6, y: 3)
            )
    }
}

struct TriggerButton: View {
    let label: String
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 52, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(settings.joystickAccent.opacity(0.3))
            )
    }
}

struct DPadView: View {
    let accent: Color

    var body: some View {
        ZStack {
            // Vertical bar
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 110)
            // Horizontal bar
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.15))
                .frame(width: 110, height: 36)
            // Center
            Circle()
                .fill(accent.opacity(0.4))
                .frame(width: 28, height: 28)
        }
    }
}

struct AnalogStickView: View {
    @Binding var offset: CGSize
    let accent: Color
    private let maxTravel: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
            Circle()
                .fill(
                    LinearGradient(colors: [accent.opacity(0.8), accent.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 58, height: 58)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let x = max(-maxTravel, min(maxTravel, value.translation.width))
                            let y = max(-maxTravel, min(maxTravel, value.translation.height))
                            offset = CGSize(width: x, height: y)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.25)) {
                                offset = .zero
                            }
                        }
                )
                .shadow(color: accent.opacity(0.5), radius: 8)
        }
    }
}
