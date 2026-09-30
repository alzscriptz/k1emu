import SwiftUI

/// Native Liquid Glass on iOS 26+, with a graceful material fallback on older iOS.
struct LiquidGlassModifier: ViewModifier {
    let enabled: Bool
    var cornerRadius: CGFloat = 22

    @ViewBuilder
    func body(content: Content) -> some View {
        if !enabled {
            content
        } else if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        } else {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                }
        }
    }
}

extension View {
    func liquidGlass(enabled: Bool = true, cornerRadius: CGFloat = 22) -> some View {
        modifier(LiquidGlassModifier(enabled: enabled, cornerRadius: cornerRadius))
    }
}
