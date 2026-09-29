import SwiftUI

struct EmulatorPlayView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Game canvas placeholder (cores render here later)
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(settings.accentColor)
                Text(game.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(game.displaySystem)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                if let tweak = appState.loadedTweakName {
                    Text("Tweak: \(tweak)")
                        .font(.caption)
                        .foregroundStyle(settings.joystickAccent)
                }
                Text("Core placeholder — real graphics render here")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
                Spacer()

                HStack(spacing: 28) {
                    controlBtn("line.3.horizontal") { appState.showInGameMenu = true }
                    if settings.tvModeEnabled {
                        controlBtn("tv") { appState.isTVModeActive.toggle() }
                    }
                    controlBtn("xmark") { appState.quitGame() }
                }
                .padding(.bottom, 36)
            }

            // FPS top-right
            VStack {
                HStack {
                    Spacer()
                    FPSOverlay()
                        .padding(.trailing, 16)
                        .padding(.top, 12)
                }
                Spacer()
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private func controlBtn(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}
