import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            settings.backgroundColor.ignoresSafeArea()

            if appState.isPlaying, let game = appState.currentGame {
                if appState.isTVModeActive {
                    // TV SHARE: ONLY the game — no controller, no chrome
                    TVGameOnlyView(game: game)
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
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.isPlaying)
        .animation(.spring(response: 0.3), value: appState.isTVModeActive)
        .sheet(isPresented: $appState.showInstallSheet) { InstallROMSheet() }
        .sheet(isPresented: $appState.showFAQ) { FAQView() }
        .sheet(item: $appState.showGameInfo) { GameInfoSheet(game: $0) }
        .sheet(item: $appState.showTweakPickerFor) { TweakPickerSheet(game: $0) }
    }
}

/// Full-screen pure game surface for AirPlay / TV share.
struct TVGameOnlyView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @ObservedObject private var fb = FrameBuffer.shared
    @ObservedObject private var chip8 = Chip8Core.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            EmulatorScreenView()
                .ignoresSafeArea()

            // Minimal exit — nearly invisible, corner tap
            VStack {
                HStack {
                    Spacer()
                    Button {
                        appState.isTVModeActive = false
                    } label: {
                        Image(systemName: "iphone")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.25))
                            .padding(16)
                    }
                }
                Spacer()
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
