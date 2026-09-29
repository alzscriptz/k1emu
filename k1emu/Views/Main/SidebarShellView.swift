import SwiftUI

/// Sketch layout: left sidebar (iOS 26 style) + main content area
struct SidebarShellView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var romLibrary: ROMLibrary

    @State private var sidebarOpen = true

    var body: some View {
        ZStack {
            AnimatedBackground().ignoresSafeArea()

            HStack(spacing: 0) {
                // SIDEBAR
                if sidebarOpen {
                    sidebar
                        .frame(width: 72)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // MAIN CONTENT
                Group {
                    switch appState.selectedTab {
                    case .emu:
                        EmuLibraryView(onToggleSidebar: { withAnimation(.spring(response: 0.3)) { sidebarOpen.toggle() } })
                    case .tweak:
                        TweakLoaderView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 8) {
            // Logo at top
            K1Logo(size: 40)
                .padding(.top, 12)
                .padding(.bottom, 8)

            sidebarBtn(.emu, icon: "gamecontroller.fill", label: "Emu")
            sidebarBtn(.tweak, icon: "slider.horizontal.3", label: "Tweak")
            sidebarBtn(.settings, icon: "gearshape.fill", label: "Settings")

            Spacer()

            // Collapse
            Button {
                withAnimation(.spring(response: 0.3)) { sidebarOpen = false }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .padding(.bottom, 16)
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.12), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                )
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
        }
    }

    private func sidebarBtn(_ tab: AppState.Tab, icon: String, label: String) -> some View {
        Button {
            appState.selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(appState.selectedTab == tab ? settings.accentColor.opacity(0.35) : .clear)
                    )
                    .foregroundStyle(appState.selectedTab == tab ? settings.accentColor : .secondary)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(appState.selectedTab == tab ? settings.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
