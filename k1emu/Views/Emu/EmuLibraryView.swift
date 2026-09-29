import SwiftUI

struct EmuLibraryView: View {
    var onToggleSidebar: (() -> Void)? = nil

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AnimatedBackground().ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar

                    if romLibrary.games.isEmpty {
                        emptyHome
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(romLibrary.games) { game in
                                    GameCard(game: game)
                                        .contentShape(Rectangle())
                                        .onTapGesture { appState.startGame(game) }
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
                                            } label {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            K1Logo(size: 40)

            VStack(alignment: .leading, spacing: 1) {
                Text("k1emu")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                Text("Your game library")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                appState.showInstallSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(settings.accentColor, in: Circle())
                    .shadow(color: settings.accentColor.opacity(0.35), radius: 12)
            }
            .accessibilityLabel("Add ROM")
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var emptyHome: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(settings.accentColor.opacity(0.10))
                    .frame(width: 128, height: 128)
                    .blur(radius: 3)

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(settings.accentColor.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                    .frame(width: 92, height: 92)

                Image(systemName: "plus")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(settings.accentColor)
            }

            VStack(spacing: 7) {
                Text("No games yet")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                Text("Add a ROM to get started!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                appState.showInstallSheet = true
            } label: {
                Label("Add ROM", systemImage: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(settings.accentColor, in: Capsule())
                    .shadow(color: settings.accentColor.opacity(0.30), radius: 16, y: 8)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct GameCard: View {
    let game: GameItem
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [settings.accentColor.opacity(0.35), settings.accentColor.opacity(0.06)],
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
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else {
                    fallbackArtwork
                }

                Text(game.displaySystem)
                    .font(.caption2.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
            }

            Text(game.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            HStack {
                Image(systemName: "play.fill")
                Text("Run")
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(settings.accentColor))
        }
    }

    private var fallbackArtwork: some View {
        Image(systemName: systemIcon(for: game.system))
            .font(.system(size: 36, weight: .medium))
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
