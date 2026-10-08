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
        Chip8Core.shared.stop()

        let path = game.fileURL.path
        let exists = FileManager.default.fileExists(atPath: path)
        let ext = (game.fileName as NSString).pathExtension.lowercased()
        let isChip8 = game.system.uppercased() == "CHIP8" || ext == "ch8" || ext == "c8"

        if isChip8 && exists {
            if Chip8Core.shared.loadROM(path: path) {
                usingBuiltinCore = true
                coreStatus = "CHIP-8 (built-in)"
                romLoadStatus = "Emulating — real pixels"
                return
            }
        }

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
                romLoadStatus = "ROM file missing: \(game.fileName)"
            }
        } else {
            coreStatus = CoreLoader.shared.lastError ?? "No core"
            if exists, let data = try? Data(contentsOf: game.fileURL),
               data.count > 0 && data.count < 3584 {
                if Chip8Core.shared.loadROM(path: path) {
                    usingBuiltinCore = true
                    coreStatus = "CHIP-8 (auto)"
                    romLoadStatus = "Emulating — real pixels"
                    return
                }
            }
            if !exists {
                romLoadStatus = "ROM missing on disk"
            } else {
                romLoadStatus = "No core for \(game.system). CHIP-8 works built-in; others need .dylib"
            }
        }
    }

    func quitGame() {
        Chip8Core.shared.stop()
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
        usingBuiltinCore = false
        selectedTab = .emu
    }
}
