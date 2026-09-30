import SwiftUI

struct AnimatedBackground: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            settings.backgroundColor

            switch settings.backgroundEffect {
            case .none:
                EmptyView()
            case .subtle:
                RadialGradient(
                    colors: [settings.accentColor.opacity(0.18), .clear],
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 460
                )
            case .aurora:
                LinearGradient(
                    colors: [settings.accentColor.opacity(0.24), .cyan.opacity(0.10), settings.backgroundColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .mesh:
                ZStack {
                    Circle().fill(settings.accentColor.opacity(0.18)).frame(width: 300).blur(radius: 90).offset(x: -120, y: -180)
                    Circle().fill(.cyan.opacity(0.10)).frame(width: 240).blur(radius: 80).offset(x: 140, y: 70)
                    Circle().fill(.purple.opacity(0.12)).frame(width: 220).blur(radius: 70).offset(x: 50, y: 250)
                }
            case .particles:
                RadialGradient(
                    colors: [settings.accentColor.opacity(0.20), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 520
                )
            case .liquid:
                LinearGradient(
                    colors: [settings.accentColor.opacity(0.18), .blue.opacity(0.08), settings.backgroundColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
