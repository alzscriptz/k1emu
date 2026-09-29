import SwiftUI

struct EmuLibraryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground().ignoresSafeArea()

                if romLibrary.games.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        // Logo + title strip
                        HStack(spacing: 12) {
                            K1Logo(size: 40)
                            VStack(alignment: .leading, spacing: 0) {
                                Text("k1emu")
                                    .font(.title3.bold())
                                Text("\(romLibrary.games.count) game\(romLibrary.games.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(romLibrary.games) { game in
                                GameCard(game: game)
                                    .contextMenu {
                                        Button { appState.showGameInfo = game } label: {
                                            Label("Info", systemImage: "info.circle")
                                        }
                                        Button { appState.showTweakPickerFor = game } label: {
                                            Label("Tweaks", systemImage: "slider.horizontal.3")
                                        }
                                        Button {} label: {
                                            Label("Multitask", systemImage: "rectangle.on.rectangle")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            withAnimation { romLibrary.delete(game) }
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
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { appState.showFAQ = true } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(settings.accentColor)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { appState.showInstallSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(settings.accentColor)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            K1Logo(size: 88)

            VStack(spacing: 8) {
                Text("No games yet")
                    .font(.title2.bold())
                Text("Tap + to install a ROM from Files or a URL.\nNothing shows here until you add something.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                appState.showInstallSheet = true
            } label: {
                Label("Install ROM", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(settings.accentColor)
                            .shadow(color: settings.accentColor.opacity(0.4), radius: 12, y: 4)
                    )
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
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                settings.accentColor.opacity(0.4),
                                settings.accentColor.opacity(0.08)
                            ],
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

                Text(game.displaySystem)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
            }

            Text(game.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            // Run hint
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.caption2)
                Text("Run")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(settings.accentColor)
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
