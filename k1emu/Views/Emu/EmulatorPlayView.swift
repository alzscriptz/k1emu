import SwiftUI

/// Placeholder play view – real cores will render here later.
struct EmulatorPlayView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Simulated game canvas
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(settings.accentColor)
                Text(game.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(game.displaySystem)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                Text("Core placeholder – real emulator cores will render here")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()

                // Simple on-screen controls hint
                HStack(spacing: 40) {
                    Button {
                        appState.showInGameMenu = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Button {
                        // Toggle TV mode manually for testing
                        if settings.tvModeEnabled {
                            appState.isTVModeActive.toggle()
                        }
                    } label: {
                        Image(systemName: "tv")
                            .font(.title)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
