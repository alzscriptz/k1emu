import SwiftUI

struct InGameMenuView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var tweakStore: TweakStore

    @State private var selectedSection: MenuSection = .tweaks

    enum MenuSection: String, CaseIterable {
        case tweaks = "Tweaks"
        case speed = "Speed"
        case keybinds = "Keybinds"
        case quit = "Quit"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    appState.showInGameMenu = false
                }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Menu")
                        .font(.title2.bold())
                    Spacer()
                    Button {
                        appState.showInGameMenu = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                // Section picker
                Picker("", selection: $selectedSection) {
                    ForEach(MenuSection.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Divider().padding(.top, 12)

                // Content
                Group {
                    switch selectedSection {
                    case .tweaks:
                        tweaksSection
                    case .speed:
                        speedSection
                    case .keybinds:
                        keybindsSection
                    case .quit:
                        quitSection
                    }
                }
                .frame(maxHeight: 320)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.blue.opacity(appState.isMouseMode ? 0.8 : 0.2), lineWidth: appState.isMouseMode ? 3 : 1)
                    )
            )
            .padding(32)
            .frame(maxWidth: 420)
        }
    }

    private var tweaksSection: some View {
        List {
            Button("None") {
                appState.loadedTweakName = nil
            }
            ForEach(tweakStore.tweaks) { t in
                Button {
                    appState.loadedTweakName = t.name
                } label: {
                    HStack {
                        Text(t.name)
                        Spacer()
                        if appState.loadedTweakName == t.name {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var speedSection: some View {
        VStack(spacing: 16) {
            Text("Gameplay Speed")
                .font(.headline)
                .padding(.top)
            HStack(spacing: 12) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { speed in
                    Button {
                        appState.gameplaySpeed = speed
                    } label: {
                        Text(speed == 1.0 ? "1×" : String(format: "%.1f×", speed))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                appState.gameplaySpeed == speed
                                ? settings.accentColor
                                : Color.white.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(appState.gameplaySpeed == speed ? .white : .primary)
                    }
                }
            }
            .padding()
            Spacer()
        }
    }

    private var keybindsSection: some View {
        List {
            LabeledContent("D-Pad", value: "Arrow Keys")
            LabeledContent("A Button", value: "Z / Space")
            LabeledContent("B Button", value: "X")
            LabeledContent("Start", value: "Enter")
            LabeledContent("Select", value: "Shift")
            LabeledContent("L / R", value: "Q / E")
            Text("Full keybind editor coming in a future update.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var quitSection: some View {
        VStack(spacing: 24) {
            Text("Quit the current game and return to the library?")
                .multilineTextAlignment(.center)
                .padding()
            Button(role: .destructive) {
                appState.showInGameMenu = false
                appState.quitGame()
            } label: {
                Text("Quit Game")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}
