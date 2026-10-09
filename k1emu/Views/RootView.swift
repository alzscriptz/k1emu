import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject private var external = ExternalDisplayManager.shared

    var body: some View {
        ZStack {
            settings.backgroundColor.ignoresSafeArea()

            if appState.isPlaying, let game = appState.currentGame {
                if appState.isTVModeActive {
                    // PHONE = controller only (no GAME panel)
                    ControllerView(game: game, showGamePanel: false)
                        .onAppear {
                            ExternalDisplayManager.shared.startGameDisplay(
                                appState: appState,
                                settings: settings
                            )
                        }
                        .onDisappear {
                            ExternalDisplayManager.shared.stopGameDisplay()
                        }
                } else {
                    ControllerView(game: game, showGamePanel: true)
                }
            } else {
                SidebarShellView()
            }

            if appState.showInGameMenu && !appState.isTVModeActive {
                InGameMenuView()
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(100)
            }

            // Hint when TV mode on but no external screen yet
            if appState.isTVModeActive && appState.isPlaying && !external.hasExternalScreen {
                VStack {
                    Spacer()
                    Text("Connect AirPlay / HDMI — TV shows the game, this phone is the controller")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 12)
                }
                .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.isPlaying)
        .animation(.spring(response: 0.3), value: appState.isTVModeActive)
        .sheet(isPresented: $appState.showInstallSheet) { InstallROMSheet() }
        .sheet(isPresented: $appState.showFAQ) { FAQView() }
        .sheet(item: $appState.showGameInfo) { GameInfoSheet(game: $0) }
        .sheet(item: $appState.showTweakPickerFor) { TweakPickerSheet(game: $0) }
        .onChange(of: appState.isTVModeActive) { active in
            if active {
                ExternalDisplayManager.shared.startGameDisplay(appState: appState, settings: settings)
            } else {
                ExternalDisplayManager.shared.stopGameDisplay()
            }
        }
    }
}
