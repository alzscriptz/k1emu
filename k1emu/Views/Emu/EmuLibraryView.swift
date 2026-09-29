import SwiftUI

struct EmuLibraryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundColor.ignoresSafeArea()

                if romLibrary.games.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(romLibrary.games) { game in
                                GameCard(game: game)
                                    .contextMenu {
                                        Button {
                                            appState.showGameInfo = game
                                        } label: {
                                            Label("Info", systemImage: "info.circle")
                                        }
                                        Button {
                                            appState.showTweakPickerFor = game
                                        } label: {
                                            Label("Tweaks", systemImage: "slider.horizontal.3")
                                        }
                                        Button {
                                            // Multitask placeholder – could open a second window / PiP later
                                        } label: {
                                            Label("Multitask", systemImage: "rectangle.on.rectangle")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            romLibrary.delete(game)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .onTapGesture {
                                        appState.startGame(game)
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("k1emu")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.showFAQ = true
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(settings.accentColor)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.showInstallSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(settings.accentColor)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 64))
                .foregroundStyle(settings.accentColor.opacity(0.6))
            Text("No ROMs yet")
                .font(.title2.bold())
            Text("Tap + to install a ROM from file or URL")
                .foregroundStyle(.secondary)
            Button {
                appState.showInstallSheet = true
            } label: {
                Label("Install ROM", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(settings.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }
}

struct GameCard: View {
    let game: GameItem
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                settings.accentColor.opacity(0.35),
                                settings.accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: systemIcon(for: game.system))
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.9))
                    )
                    .modifier(LiquidGlassModifier(enabled: settings.useLiquidGlass))

                // System badge
                Text(game.displaySystem)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
            }

            Text(game.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let tweak = game.appliedTweakID {
                Text("Tweak loaded")
                    .font(.caption2)
                    .foregroundStyle(settings.joystickAccent)
            }
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
        case "NDS": return "rectangle.split.2x1"
        default: return "opticaldisc.fill"
        }
    }
}
