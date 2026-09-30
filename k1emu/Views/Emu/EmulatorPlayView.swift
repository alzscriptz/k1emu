import SwiftUI

struct EmulatorPlayView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 8) {
                    gameScreen
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .padding(.horizontal, 12)

                    Spacer(minLength: 0)

                    phoneControls
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)

                VStack {
                    HStack {
                        Spacer()
                        FPSOverlay()
                            .padding(.trailing, 18)
                            .padding(.top, 12)
                    }
                    Spacer()
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var gameScreen: some View {
        ZStack {
            LinearGradient(
                colors: [.black, settings.accentColor.opacity(0.16), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                HStack(spacing: 14) {
                    Label("x05", systemImage: "star.fill")
                    Label("x23", systemImage: "circle.fill")
                    Spacer()
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .padding(16)

                Spacer()

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(settings.accentColor)

                Text(game.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                if let tweak = appState.loadedTweakName {
                    Text(tweak)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 12)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: settings.accentColor.opacity(0.14), radius: 22)
    }

    // Xbox-style touch layout: D-pad on the left, A/B/X/Y in a diamond on the right.
    // No +/- symbols and no square button boxes.
    private var phoneControls: some View {
        HStack(alignment: .bottom) {
            TouchDPadView()
                .frame(width: 126, height: 126)

            Spacer()

            XboxFaceButtons(
                onA: {},
                onB: {},
                onX: {},
                onY: {}
            )
            .frame(width: 148, height: 148)
        }
        .frame(height: 150)
    }
}

private struct TouchDPadView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 122, height: 122)

            VStack(spacing: 0) {
                dpadButton("chevron.up")
                HStack(spacing: 0) {
                    dpadButton("chevron.left")
                    Color.clear.frame(width: 42, height: 42)
                    dpadButton("chevron.right")
                }
                dpadButton("chevron.down")
            }
        }
    }

    private func dpadButton(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white.opacity(0.78))
            .frame(width: 42, height: 42)
            .background(.white.opacity(0.10), in: Circle())
    }
}

private struct XboxFaceButtons: View {
    let onA: () -> Void
    let onB: () -> Void
    let onX: () -> Void
    let onY: () -> Void

    var body: some View {
        ZStack {
            faceButton("Y", action: onY)
                .offset(y: -46)

            faceButton("X", action: onX)
                .offset(x: -46)

            faceButton("B", action: onB)
                .offset(x: 46)

            faceButton("A", action: onA)
                .offset(y: 46)
        }
    }

    private func faceButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.20), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
