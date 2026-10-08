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

        let ext = (game.fileName as NSString).pathExtension.lowercased()
        let isChip8 = game.system.uppercased() == "CHIP8" || ext == "ch8" || ext == "c8"

        // Prefer built-in CHIP-8 for real pixels when applicable
        if isChip8, let path = game.fileURL?.path,
           FileManager.default.fileExists(atPath: path) {
            if Chip8Core.shared.loadROM(path: path) {
                usingBuiltinCore = true
                coreStatus = "CHIP-8 (built-in)"
                romLoadStatus = "Emulating — real pixels"
                return
            }
        }

        // External dylib cores
        let ok = CoreLoader.shared.loadCore(for: game.system)
        if ok, let name = CoreLoader.shared.loadedCoreName {
            coreStatus = name
            if let path = game.fileURL?.path,
               FileManager.default.fileExists(atPath: path) {
                if CoreLoader.shared.loadGame(path: path) {
                    romLoadStatus = "ROM loaded — needs video callback from core"
                } else {
                    romLoadStatus = CoreLoader.shared.lastError ?? "ROM load failed"
                }
            } else {
                romLoadStatus = "ROM file missing on disk"
            }
        } else {
            coreStatus = CoreLoader.shared.lastError ?? "No core"
            // Fallback: if file looks like CHIP-8 size, try builtin anyway
            if let path = game.fileURL?.path,
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               data.count > 0 && data.count < 3584 {
                if Chip8Core.shared.loadROM(path: path) {
                    usingBuiltinCore = true
                    coreStatus = "CHIP-8 (auto)"
                    romLoadStatus = "Emulating — real pixels"
                    return
                }
            }
            romLoadStatus = "No core for \(game.system). Use CHIP-8 (.ch8) for built-in pixels, or drop ios-arm64 dylib in Cores/"
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
