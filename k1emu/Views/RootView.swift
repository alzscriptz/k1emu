import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var externalDisplay: ExternalDisplayManager

    var body: some View {
        ZStack {
            settings.backgroundColor.ignoresSafeArea()

            if appState.isPlaying, let game = appState.currentGame {
                ControllerView(game: game, showGamePanel: !appState.isTVModeActive)
            } else {
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
        .onAppear {
            externalDisplay.connect(appState: appState, settings: settings)
        }
        .onChange(of: appState.isPlaying) { _, _ in externalDisplay.refresh() }
        .onChange(of: appState.currentGame) { _, _ in externalDisplay.refresh() }
        .onChange(of: settings.tvModeEnabled) { _, _ in externalDisplay.refresh() }
        .sheet(isPresented: $appState.showInstallSheet) { InstallROMSheet() }
        .sheet(isPresented: $appState.showFAQ) { FAQView() }
        .sheet(item: $appState.showGameInfo) { game in GameInfoSheet(game: game) }
        .sheet(item: $appState.showTweakPickerFor) { game in TweakPickerSheet(game: game) }
    }
}
