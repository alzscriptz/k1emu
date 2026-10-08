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
    /// Browser content shown inside the Browser panel (not a full-screen mode)
    @Published var showBrowserInPanel: Bool = false
    /// Keyboard shown inside Browser panel (for text entry games)
    @Published var showKeyboardInPanel: Bool = false
    @Published var isMouseMode: Bool = false
    @Published var showInGameMenu: Bool = false
    @Published var gameplaySpeed: Double = 1.0
    @Published var loadedTweakName: String? = nil
    @Published var coreStatus: String = "No core"
    @Published var romLoadStatus: String = ""
    @Published var usingBuiltinCore: Bool = false

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
        usingBuiltinCore = false
        showBrowserInPanel = false
        showKeyboardInPanel = false
        Chip8Core.shared.stop()

        CoreLoader.shared.prepareBundledCores()

        let path = game.fileURL.path
        let exists = FileManager.default.fileExists(atPath: path)
        let ext = (game.fileName as NSString).pathExtension.lowercased()
        let isChip8 = game.system.uppercased() == "CHIP8" || ext == "ch8" || ext == "c8"

        if isChip8 && exists {
            if Chip8Core.shared.loadROM(path: path) {
                usingBuiltinCore = true
                coreStatus = "CHIP-8"
                romLoadStatus = "Running"
                return
            }
        }

        // NDS and others via dylib
        let ok = CoreLoader.shared.loadCore(for: game.system)
        if ok, let name = CoreLoader.shared.loadedCoreName {
            coreStatus = name
            if exists {
                if CoreLoader.shared.loadGame(path: path) {
                    romLoadStatus = "ROM loaded"
                } else {
                    romLoadStatus = CoreLoader.shared.lastError ?? "ROM load failed"
                }
            } else {
                romLoadStatus = "ROM missing: \(game.fileName)"
            }
        } else {
            coreStatus = "Load failed"
            romLoadStatus = CoreLoader.shared.lastError ?? "No core"
        }
    }

    func quitGame() {
        Chip8Core.shared.stop()
        CoreLoader.shared.unload()
        isPlaying = false
        currentGame = nil
        isTVModeActive = false
        showBrowserInPanel = false
        showKeyboardInPanel = false
        isMouseMode = false
        showInGameMenu = false
        loadedTweakName = nil
        coreStatus = "No core"
        romLoadStatus = ""
        usingBuiltinCore = false
        selectedTab = .emu
    }

    func toggleBrowserPanel() {
        showKeyboardInPanel = false
        showBrowserInPanel.toggle()
    }

    func toggleKeyboardPanel() {
        showBrowserInPanel = false
        showKeyboardInPanel.toggle()
    }
}
