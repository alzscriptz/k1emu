import SwiftUI

@main
struct k1emuApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settings = SettingsStore()
    @StateObject private var romLibrary = ROMLibrary()
    @StateObject private var tweakStore = TweakStore()
    @StateObject private var externalDisplay = ExternalDisplayManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(settings)
                .environmentObject(romLibrary)
                .environmentObject(tweakStore)
                .environmentObject(externalDisplay)
                .preferredColorScheme(settings.colorScheme)
        }
    }
}
