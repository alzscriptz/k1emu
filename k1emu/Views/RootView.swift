import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            settings.backgroundColor.ignoresSafeArea()

            if appState.isPlaying, let game = appState.currentGame {
                if appState.isTVModeActive {
                    // Phone is now the controller – game is on external display
                    ControllerView(game: game)
                } else {
                    EmulatorPlayView(game: game)
                }
            } else {
                MainTabView()
            }

            // In-game menu overlay (works in both normal + TV mode)
            if appState.showInGameMenu {
                InGameMenuView()
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.isPlaying)
        .animation(.spring(response: 0.3), value: appState.showInGameMenu)
        .sheet(isPresented: $appState.showInstallSheet) {
            InstallROMSheet()
        }
        .sheet(isPresented: $appState.showFAQ) {
            FAQView()
        }
        .sheet(item: $appState.showGameInfo) { game in
            GameInfoSheet(game: game)
        }
        .sheet(item: $appState.showTweakPickerFor) { game in
            TweakPickerSheet(game: game)
        }
    }
}
