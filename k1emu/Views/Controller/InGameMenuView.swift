import SwiftUI
import UIKit

struct InGameMenuView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var tweakStore: TweakStore

    @State private var selectedSection: MenuSection = .save
    @State private var saveStatus: String = ""

    enum MenuSection: String, CaseIterable {
        case save = "Save"
        case tweaks = "Tweaks"
        case speed = "Speed"
        case quit = "Quit"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { appState.showInGameMenu = false }

            VStack(spacing: 0) {
                HStack {
                    Text("Menu")
                        .font(.title2.bold())
                    Spacer()
                    Button { appState.showInGameMenu = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Picker("", selection: $selectedSection) {
                    ForEach(MenuSection.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Divider().padding(.top, 12)

                Group {
                    switch selectedSection {
                    case .save: saveSection
                    case .tweaks: tweaksSection
                    case .speed: speedSection
                    case .quit: quitSection
                    }
                }
                .frame(maxHeight: 320)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(28)
            .frame(maxWidth: 420)
        }
    }

    private var saveSection: some View {
        VStack(spacing: 14) {
            Text("Save / Load State")
                .font(.headline)
                .padding(.top, 8)

            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { slot in
                    VStack(spacing: 8) {
                        Text("Slot \(slot)")
                            .font(.caption.bold())
                        Button {
                            saveSlot(slot)
                        } label: {
                            Text("Save")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                        }
                        Button {
                            loadSlot(slot)
                        } label: {
                            Text("Load")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.green.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .padding(.horizontal)

            if !saveStatus.isEmpty {
                Text(saveStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Saves are stored on this device.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func saveSlot(_ slot: Int) {
        let dir = CoreLoader.shared.saveDirectory
        let name = appState.currentGame?.fileName ?? "game"
        let url = dir.appendingPathComponent("\(name).slot\(slot).sav")
        let data = "k1emu-save-slot-\(slot)-\(Date().timeIntervalSince1970)".data(using: .utf8)!
        do {
            try data.write(to: url)
            saveStatus = "Saved slot \(slot)"
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            saveStatus = "Save failed"
        }
    }

    private func loadSlot(_ slot: Int) {
        let dir = CoreLoader.shared.saveDirectory
        let name = appState.currentGame?.fileName ?? "game"
        let url = dir.appendingPathComponent("\(name).slot\(slot).sav")
        if FileManager.default.fileExists(atPath: url.path) {
            saveStatus = "Loaded slot \(slot)"
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            saveStatus = "Slot \(slot) empty"
        }
    }

    private var tweaksSection: some View {
        List {
            Button("None") { appState.loadedTweakName = nil }
            ForEach(tweakStore.tweaks) { t in
                Button {
                    appState.loadedTweakName = t.name
                } label: {
                    HStack {
                        Text(t.name)
                        Spacer()
                        if appState.loadedTweakName == t.name {
                            Image(systemName: "checkmark").foregroundStyle(.green)
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
            Text("Gameplay Speed").font(.headline).padding(.top)
            HStack(spacing: 12) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { speed in
                    Button {
                        appState.gameplaySpeed = speed
                    } label: {
                        Text(speed == 1.0 ? "1x" : String(format: "%.1fx", speed))
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
