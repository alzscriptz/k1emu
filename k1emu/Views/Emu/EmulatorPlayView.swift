import SwiftUI

struct EmulatorPlayView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 12) {
                    gameScreen
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .padding(.horizontal, 12)

                    Spacer(minLength: 0)

                    phoneControls
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
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

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.10))
                        .frame(width: 76, height: 76)
                        .blur(radius: 5)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(settings.accentColor)
                }

                Text(game.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                HStack {
                    Text(game.displaySystem)
                    if let tweak = appState.loadedTweakName {
                        Text("• \(tweak)")
                    }
                }
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 12)
            }
            .padding(2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: settings.accentColor.opacity(0.14), radius: 22)
    }

    private var phoneControls: some View {
        HStack {
            ZStack {
                Circle().fill(.white.opacity(0.08)).frame(width: 106, height: 106)
                Image(systemName: "plus")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .overlay {
                Circle().stroke(.white.opacity(0.16), lineWidth: 1)
            }

            Spacer()

            HStack(spacing: 14) {
                control("xmark")
                control("y")
                control("b")
                control("a")
            }
        }
    }

    private func control(_ title: String) -> some View {
        Button {
            if title == "xmark" { appState.showInGameMenu = true }
            if title == "b" { appState.quitGame() }
        } label: {
            Text(title.uppercased())
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
