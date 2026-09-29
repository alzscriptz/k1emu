import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            settings.backgroundColor.ignoresSafeArea()

            if appState.isPlaying, let game = appState.currentGame {
                if appState.isTVModeActive {
                    // TV mode: phone is full controller only
                    ControllerView(game: game, showGamePanel: false)
                } else {
                    // ON PHONE MODE (sketch): game panel + controller on same screen
                    ControllerView(game: game, showGamePanel: true)
                }
            } else {
                // Main shell: SIDEBAR + content (matches sketch)
                SidebarShellView()
            }

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
