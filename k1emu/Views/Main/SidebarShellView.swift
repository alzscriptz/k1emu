import SwiftUI

/// Horizontal liquid-glass bottom bar + main content (no vertical sidebar).
struct SidebarShellView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var romLibrary: ROMLibrary

    var body: some View {
        ZStack {
            AnimatedBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                // MAIN CONTENT
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

                // HORIZONTAL liquid-glass bar
                horizontalBar
            }
        }
        .onAppear {
            romLibrary.scanDocumentsForROMs()
        }
    }

    private var horizontalBar: some View {
        HStack(spacing: 0) {
            barBtn(.emu, icon: "gamecontroller.fill", label: "Emu")
            barBtn(.tweak, icon: "slider.horizontal.3", label: "Tweak")
            barBtn(.settings, icon: "gearshape.fill", label: "Settings")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func barBtn(_ tab: AppState.Tab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 48, height: 36)
                    .background(
                        Capsule()
                            .fill(appState.selectedTab == tab ? settings.accentColor.opacity(0.35) : .clear)
                    )
                    .foregroundStyle(appState.selectedTab == tab ? settings.accentColor : .secondary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(appState.selectedTab == tab ? settings.accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

/// Soft animated background under glass chrome
struct AnimatedBackground: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        LinearGradient(
            colors: [
                settings.backgroundColor,
                settings.backgroundColor.opacity(0.85),
                settings.accentColor.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
