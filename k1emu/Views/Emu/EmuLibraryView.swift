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
                if let onToggleSidebar {
                    Button(action: onToggleSidebar) {
                        Image(systemName: "sidebar.left")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                Button { appState.showFAQ = true } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(settings.accentColor)
                }

                Spacer()

                HStack(spacing: 8) {
                    K1Logo(size: 28)
                    Text("k1emu").font(.headline.bold())
                }

                Spacer()

                Button { appState.showInstallSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(settings.accentColor)
                }
                .accessibilityLabel("Add ROM")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if romLibrary.games.isEmpty {
                // Deliberately empty: the home screen never invents content.
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(romLibrary.games) { game in
                            GameCard(game: game)
                                .contentShape(Rectangle())
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
                                .onTapGesture { appState.startGame(game) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct GameCard: View {
    let game: GameItem
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [settings.accentColor.opacity(0.38), settings.accentColor.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                if let coverURL = game.coverURL {
                    AsyncImage(url: coverURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            fallbackArtwork
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    fallbackArtwork
                }

                Text(game.displaySystem)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
            }

            Text(game.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            HStack {
                Image(systemName: "play.fill").font(.caption2)
                Text("Run").font(.caption2.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(settings.accentColor))
        }
    }

    private var fallbackArtwork: some View {
        Image(systemName: systemIcon(for: game.system))
            .font(.system(size: 34, weight: .medium))
            .foregroundStyle(.white.opacity(0.95))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
