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
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    tvGameFrame
                        .frame(maxWidth: min(proxy.size.width - 40, 1120))
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)

                    Spacer()
                }
                .padding(.top, 20)

                VStack {
                    HStack {
                        Spacer()
                        FPSOverlay()
                            .padding(.trailing, 28)
                            .padding(.top, 24)
                    }
                    Spacer()
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var tvGameFrame: some View {
        ZStack {
            LinearGradient(
                colors: [.black, settings.accentColor.opacity(0.13), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                HStack(spacing: 18) {
                    Label("x05", systemImage: "star.fill")
                    Label("x23", systemImage: "circle.fill")
                    Spacer()
                }
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .padding(24)

                Spacer()

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 100, weight: .medium))
                    .foregroundStyle(settings.accentColor)
                    .shadow(color: settings.accentColor.opacity(0.30), radius: 24)

                Text(game.name)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            if settings.target4KWhenStable && is4KDisplay {
                Text("4K")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(18)
            }
        }
        .shadow(color: .black.opacity(0.45), radius: 30, y: 18)
    }
}
