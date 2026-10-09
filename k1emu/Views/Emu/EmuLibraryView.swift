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
                Button { appState.showFAQ = true } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(settings.accentColor)
                }

                Spacer()

                Text("k1emu").font(.headline.bold())

                Spacer()

                Button {
                    romLibrary.scanDocumentsForROMs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

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
                        ForEach(romLibrary.games, id: \.id) { item in
                            GameCard(game: item) {
                                romLibrary.markPlayed(item)
                                appState.startGame(item)
                            }
                            .contextMenu {
                                Button { appState.showGameInfo = item } label: {
                                    Label("Info", systemImage: "info.circle")
                                }
                                Button { appState.showTweakPickerFor = item } label: {
                                    Label("Tweaks", systemImage: "slider.horizontal.3")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    romLibrary.delete(item)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onAppear { romLibrary.scanDocumentsForROMs() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No games yet")
                .font(.title3.bold())
            Text("Tap + to add a ROM, or drop files into\nFiles → On My iPhone → k1emu")
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
                            .stroke(LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )

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

            Button(action: onRun) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                    Text("Play")
                }
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(settings.accentColor.opacity(0.9)))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private func systemIcon(for system: String) -> String {
        switch system.uppercased() {
        case "NDS": return "n.square.fill"
        case "GBA", "GB", "GBC": return "gamecontroller.fill"
        case "NES", "SNES": return "tv.fill"
        case "N64": return "cube.fill"
        default: return "opticaldisc.fill"
        }
    }
}
