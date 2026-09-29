import SwiftUI

struct ControllerView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    @State private var leftStick: CGSize = .zero
    @State private var rightStick: CGSize = .zero

    var body: some View {
        ZStack {
            settings.joystickColor.ignoresSafeArea()

            if appState.isBrowserMode {
                BrowserModeView()
            } else {
                controllerLayout
            }

            // FPS always top-right on TV / controller mode
            VStack {
                HStack {
                    Spacer()
                    FPSOverlay()
                        .padding(.trailing, 14)
                        .padding(.top, 10)
                }
                Spacer()
            }

            if appState.isMouseMode {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.blue, lineWidth: 4)
                    .padding(6)
                    .allowsHitTesting(false)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var controllerLayout: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    ControllerButton(systemName: "line.3.horizontal", size: 42) {
                        appState.showInGameMenu = true
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        ControllerButton(systemName: "rectangle.on.rectangle", size: 38) {
                            appState.isMouseMode.toggle()
                        }
                        ControllerButton(systemName: "rectangle.on.rectangle", size: 38) {
                            appState.isMouseMode.toggle()
                        }
                    }

                    Spacer()

                    Button {
                        appState.isBrowserMode.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(settings.joystickAccent.opacity(0.25))
                                .frame(width: 46, height: 46)
                            Image(systemName: "safari.fill")
                                .font(.title3)
                                .foregroundStyle(settings.joystickAccent)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Game title chip
                Text(game.name)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 6)

                Spacer()

                HStack(alignment: .center, spacing: 0) {
                    VStack(spacing: 24) {
                        DPadView(accent: settings.joystickAccent)
                        AnalogStickView(offset: $leftStick, accent: settings.joystickAccent)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 14) {
                        HStack(spacing: 18) {
                            FaceButton(label: "Y", color: .yellow)
                            FaceButton(label: "X", color: .blue)
                        }
                        HStack(spacing: 18) {
                            FaceButton(label: "B", color: .red)
                            FaceButton(label: "A", color: .green)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 24) {
                        AnalogStickView(offset: $rightStick, accent: settings.joystickAccent)
                        HStack(spacing: 12) {
                            TriggerButton(label: "LT")
                            TriggerButton(label: "RT")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)

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
                .font(.system(size: size * 0.42))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(settings.joystickColor)
                        .shadow(color: .black.opacity(0.45), radius: 4, y: 2)
                )
                .overlay(
                    Circle().stroke(settings.joystickAccent.opacity(0.45), lineWidth: 1.5)
                )
        }
    }
}

struct FaceButton: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.title3.bold())
            .foregroundStyle(.white)
            .frame(width: 54, height: 54)
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
            .frame(width: 50, height: 26)
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
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.14))
                .frame(width: 34, height: 104)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.14))
                .frame(width: 104, height: 34)
            Circle()
                .fill(accent.opacity(0.35))
                .frame(width: 26, height: 26)
        }
    }
}

struct AnalogStickView: View {
    @Binding var offset: CGSize
    let accent: Color
    private let maxTravel: CGFloat = 34

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 96, height: 96)
            Circle()
                .fill(
                    LinearGradient(colors: [accent.opacity(0.85), accent.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 54, height: 54)
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
                .shadow(color: accent.opacity(0.5), radius: 8)
        }
    }
}
