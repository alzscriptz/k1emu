import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .emu
    @Published var isPlaying: Bool = false
    @Published var currentGame: GameItem?
    @Published var showInstallSheet: Bool = false
    @Published var showFAQ: Bool = false
    @Published var showGameInfo: GameItem?
    @Published var showTweakPickerFor: GameItem?
    @Published var isTVModeActive: Bool = false
    @Published var isBrowserMode: Bool = false
    @Published var isMouseMode: Bool = false
    @Published var showInGameMenu: Bool = false
    @Published var gameplaySpeed: Double = 1.0
    @Published var loadedTweakName: String? = nil
    @Published var coreStatus: String = "No core"
    @Published var romLoadStatus: String = ""

    enum Tab: String, CaseIterable {
        case emu = "Emu"
        case tweak = "Tweak"
        case settings = "Settings"
    }

    func startGame(_ game: GameItem) {
        currentGame = game
        isPlaying = true
        loadedTweakName = nil
        romLoadStatus = ""

        let ok = CoreLoader.shared.loadCore(for: game.system)
        if ok, let name = CoreLoader.shared.loadedCoreName {
            coreStatus = name
            // Try to load the ROM file into the core
            if let path = game.fileURL?.path,
               FileManager.default.fileExists(atPath: path) {
                if CoreLoader.shared.loadGame(path: path) {
                    romLoadStatus = "ROM loaded"
                } else {
                    romLoadStatus = CoreLoader.shared.lastError ?? "ROM load failed (core may need BIOS / different format)"
                }
            } else {
                romLoadStatus = "ROM file missing on disk"
            }
        } else {
            coreStatus = CoreLoader.shared.lastError ?? "No core"
            romLoadStatus = "Drop an ios-arm64 core dylib into Cores/ to run this system"
        }
    }

    func quitGame() {
        CoreLoader.shared.unload()
        isPlaying = false
        currentGame = nil
        isTVModeActive = false
        isBrowserMode = false
        isMouseMode = false
        showInGameMenu = false
        loadedTweakName = nil
        coreStatus = "No core"
        romLoadStatus = ""
        selectedTab = .emu
    }
}
