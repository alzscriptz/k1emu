import SwiftUI

/// Large three-section bottom navigation inspired by the sketch.
struct SidebarShellView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
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
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomDock
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
    }

    private var bottomDock: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 10) {
                    dockContent
                }
            } else {
                dockContent
            }
        }
    }

    private var dockContent: some View {
        HStack(spacing: 7) {
            dockButton(.emu, icon: "gamecontroller.fill", label: "Emu")
            dockButton(.tweak, icon: "slider.horizontal.3", label: "Tweaks")
            dockButton(.settings, icon: "gearshape.fill", label: "Settings")
        }
        .padding(8)
        .frame(maxWidth: 760)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.black.opacity(0.18))
        }
        .liquidGlass(cornerRadius: 30)
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 28, y: 14)
    }

    private func dockButton(_ tab: AppState.Tab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.80)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))

                Text(label)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(appState.selectedTab == tab ? settings.accentColor : .secondary)
            .frame(maxWidth: .infinity, minHeight: 68)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .background {
                if appState.selectedTab == tab {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(settings.accentColor.opacity(0.18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(settings.accentColor.opacity(0.38), lineWidth: 1)
                        }
                        .shadow(color: settings.accentColor.opacity(0.20), radius: 14)
                    Circle()
                        .fill(settings.accentColor.opacity(0.24))
                        .frame(width: 46, height: 46)
                        .blur(radius: 15)
                }
            }
            .liquidGlass(cornerRadius: 22)
            .scaleEffect(appState.selectedTab == tab ? 1.015 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
