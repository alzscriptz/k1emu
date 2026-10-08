import SwiftUI

@main
struct k1emuApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settings = SettingsStore()
    @StateObject private var romLibrary = ROMLibrary()
    @StateObject private var tweakStore = TweakStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(settings)
                .environmentObject(romLibrary)
                .environmentObject(tweakStore)
                .preferredColorScheme(settings.colorScheme)
                .onAppear {
                    CoreLoader.shared.prepareBundledCores()
                }
        }
    }
}
