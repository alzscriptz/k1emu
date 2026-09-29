import SwiftUI

/// Main navigation is intentionally horizontal: the sketch's vertical rail is replaced
/// by a floating bottom dock, which leaves the game/library surface unobstructed.
struct SidebarShellView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack(alignment: .bottom) {
            AnimatedBackground()
                .ignoresSafeArea()

            Group {
                switch appState.selectedTab {
                case .emu:
                    EmuLibraryView()
                case .tweak:
                    TweakLoaderView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomDock
                .padding(.horizontal, 22)
                .padding(.bottom, 10)
        }
    }

    private var bottomDock: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 12) {
                    dockContent
                }
            } else {
                dockContent
            }
        }
    }

    private var dockContent: some View {
        HStack(spacing: 10) {
            dockButton(.emu, icon: "gamecontroller.fill", label: "Emu")
            dockButton(.tweak, icon: "slider.horizontal.3", label: "Tweaks")
            dockButton(.settings, icon: "gearshape.fill", label: "Settings")
        }
        .padding(9)
        .liquidGlass()
        .shadow(color: .black.opacity(0.28), radius: 24, y: 12)
    }

    private func dockButton(_ tab: AppState.Tab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                appState.selectedTab = tab
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(appState.selectedTab == tab ? settings.accentColor : .secondary)
            .frame(minWidth: 82, minHeight: 44)
            .contentShape(Capsule())
            .background {
                if appState.selectedTab == tab {
                    Capsule()
                        .fill(settings.accentColor.opacity(0.18))
                        .overlay {
                            Capsule().stroke(settings.accentColor.opacity(0.35), lineWidth: 1)
                        }
                }
            }
            .liquidGlass(cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
