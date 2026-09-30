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

    enum Tab: String, CaseIterable {
        case emu = "Emu"
        case tweak = "Tweak"
        case settings = "Settings"
    }

    func startGame(_ game: GameItem) {
        currentGame = game
        isPlaying = true
        loadedTweakName = nil
        let ok = CoreLoader.shared.loadCore(for: game.system)
        if ok, let name = CoreLoader.shared.loadedCoreName {
            coreStatus = name
        } else {
            coreStatus = CoreLoader.shared.lastError ?? "No core"
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
        selectedTab = .emu
    }
}
