import SwiftUI

/// Immersive gameplay surface. Gameplay fills the available screen; the menu is
/// hidden by default and only appears when the player taps the screen.
struct EmulatorPlayView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @State private var controlsVisible = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if appState.usingBuiltinCore || CoreLoader.shared.isLibretro {
                    EmulatorScreenView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    unavailableState
                }

                if controlsVisible {
                    VStack {
                        HStack(spacing: 12) {
                            statusPill
                            Spacer()
                            controlBtn("line.3.horizontal", label: "Game menu") {
                                appState.showInGameMenu = true
                                controlsVisible = false
                            }
                            if settings.tvModeEnabled {
                                controlBtn("tv", label: "External display") {
                                    appState.isTVModeActive.toggle()
                                    controlsVisible = false
                                }
                            }
                            controlBtn("xmark", label: "Quit game") {
                                appState.quitGame()
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        Spacer()
                        Text("Tap the game to hide controls")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.65))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 12)
                    }
                    .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.18)) {
                    controlsVisible.toggle()
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .background(Color.black.ignoresSafeArea())
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 42))
                .foregroundStyle(settings.accentColor)
            Text(game.name)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(game.displaySystem)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
            Text(appState.romLoadStatus.isEmpty ? "No compatible emulator core is running." : appState.romLoadStatus)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
            Text("This game cannot render until a compatible core successfully loads.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.55))
            Button("Back to library") { appState.quitGame() }
                .buttonStyle(.borderedProminent)
                .tint(settings.accentColor)
                .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: 420)
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill((appState.usingBuiltinCore || CoreLoader.shared.isLibretro) ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(appState.coreStatus)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func controlBtn(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
