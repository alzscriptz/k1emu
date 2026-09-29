import SwiftUI

/// Applies liquid-glass / advanced material when available (iOS 18+ / future 26+),
/// otherwise falls back to ultraThinMaterial + subtle gradient.
struct LiquidGlassModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            if #available(iOS 18.0, *) {
                // On iOS 18+ we use the newest material APIs.
                // When Apple ships the full “Liquid Glass” system material in a later OS
                // (sometimes referred to as iOS 26 in early discussions) this will pick it up.
                content
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.35), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            } else {
                content
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        } else {
            content
        }
    }
}

extension View {
    func liquidGlass(enabled: Bool = true) -> some View {
        modifier(LiquidGlassModifier(enabled: enabled))
    }
}
