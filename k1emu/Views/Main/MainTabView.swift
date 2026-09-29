import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            EmuLibraryView()
                .tabItem {
                    Label("Emu", systemImage: "gamecontroller.fill")
                }
                .tag(AppState.Tab.emu)

            TweakLoaderView()
                .tabItem {
                    Label("Tweak", systemImage: "slider.horizontal.3")
                }
                .tag(AppState.Tab.tweak)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppState.Tab.settings)
        }
        .tint(settings.accentColor)
        .onAppear {
            // Make tab bar glassier on supported OS
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            if #available(iOS 18.0, *) {
                // Future liquid glass will pick this up automatically
            }
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}
