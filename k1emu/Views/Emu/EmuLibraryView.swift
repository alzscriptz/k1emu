import SwiftUI

struct EmuLibraryView: View {
    var onToggleSidebar: (() -> Void)? = nil

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { onToggleSidebar?() } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Button { appState.showFAQ = true } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(settings.accentColor)
                }

                Spacer()

                HStack(spacing: 8) {
                    K1Logo(size: 28)
                    Text("k1emu")
                        .font(.headline.bold())
                }

                Spacer()

                Button { appState.showInstallSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(settings.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if romLibrary.games.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(romLibrary.games) { game in
                            GameCard(game: game) {
                                romLibrary.markPlayed(game)
                                appState.startGame(game)
                            }
                            .contextMenu {
                                Button { appState.showGameInfo = game } label: {
                                    Label("Info", systemImage: "info.circle")
                                }
                                Button { appState.showTweakPickerFor = game } label: {
                                    Label("Tweaks", systemImage: "slider.horizontal.3")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    withAnimation { romLibrary.delete(game) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            K1Logo(size: 80)
            Text("No games yet")
                .font(.title2.bold())
            Text("Tap + to add a ROM\nSupports .zip, .nds, .gba, .nes, .sfc, .n64, .iso…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button { appState.showInstallSheet = true } label: {
                Label("Install ROM", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(settings.accentColor))
                    .foregroundStyle(.white)
                    .shadow(color: settings.accentColor.opacity(0.4), radius: 12, y: 4)
            }
        }
    }
}

struct GameCard: View {
    let game: GameItem
    var onRun: () -> Void
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [settings.accentColor.opacity(0.4), settings.accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: systemIcon(for: game.system))
                            .font(.system(size: 34))
                            .foregroundStyle(.white.opacity(0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .liquidGlass(enabled: settings.useLiquidGlass)

                Text(game.displaySystem)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
            }
            .contentShape(Rectangle())
            .onTapGesture { onRun() }

            Text(game.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            // Real Run button
            Button(action: onRun) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill").font(.caption2)
                    Text("Run").font(.caption2.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(settings.accentColor))
            }
            .buttonStyle(.plain)
        }
    }

    private func systemIcon(for system: String) -> String {
        switch system.uppercased() {
        case "NES", "FC": return "rectangle.grid.2x2"
        case "SNES", "SFC": return "square.grid.3x3"
        case "N64": return "cube"
        case "GB", "GBC": return "gamecontroller"
        case "GBA": return "gamecontroller.fill"
        case "PS1", "PSX": return "opticaldisc"
        case "NDS", "DS": return "rectangle.split.2x1"
        default: return "opticaldisc.fill"
        }
    }
}
