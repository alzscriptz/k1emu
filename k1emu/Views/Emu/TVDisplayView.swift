import SwiftUI
import UIKit

struct TVDisplayView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    private var externalScreen: UIScreen? {
        UIScreen.screens.first(where: { $0 != UIScreen.main })
    }

    private var is4KDisplay: Bool {
        guard let screen = externalScreen else { return false }
        let size = screen.nativeBounds.size
        return max(size.width, size.height) >= 3840 && min(size.width, size.height) >= 2160
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // This is the external-display surface. The real core renderer can
            // replace the placeholder without changing the TV shell or FPS HUD.
            VStack(spacing: 18) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 92, weight: .medium))
                    .foregroundStyle(settings.accentColor)

                Text(game.name)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(game.displaySystem) • \(appState.coreStatus)")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))

                if settings.target4KWhenStable && is4KDisplay {
                    Label("4K OUTPUT", systemImage: "4k.tv.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(settings.joystickAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(settings.joystickAccent.opacity(0.12), in: Capsule())
                }
            }
            .drawingGroup(opaque: true, colorMode: .extendedLinear)

            VStack {
                HStack {
                    Spacer()
                    FPSOverlay()
                        .padding(.trailing, 24)
                        .padding(.top, 20)
                }
                Spacer()
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
