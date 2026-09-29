import SwiftUI
import Combine

enum BackgroundEffect: String, CaseIterable, Identifiable {
    case none = "None"
    case subtle = "Subtle Glow"
    case aurora = "Aurora"
    case mesh = "Mesh Gradient"
    case particles = "Particles"
    case liquid = "Liquid Glass"

    var id: String { rawValue }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var backgroundColor: Color = Color(hex: "0B0B10")
    @Published var accentColor: Color = Color(hex: "7C5CFF")
    @Published var joystickColor: Color = Color(hex: "1C1C24")
    @Published var joystickAccent: Color = Color(hex: "00E5FF")
    @Published var backgroundEffect: BackgroundEffect = .liquid
    @Published var useLiquidGlass: Bool = true
    @Published var colorScheme: ColorScheme? = .dark
    @Published var showFPS: Bool = true
    @Published var target4KWhenStable: Bool = true

    @Published var tvModeEnabled: Bool = true
    @Published var autoEnterControllerOnExternalDisplay: Bool = true

    static let backgroundPresets: [(String, Color)] = [
        ("Void", Color(hex: "0B0B10")),
        ("Midnight", Color(hex: "0E0E18")),
        ("Ocean Depth", Color(hex: "061018")),
        ("Forest", Color(hex: "0A140E")),
        ("Nebula", Color(hex: "12081E")),
        ("Ember", Color(hex: "160808")),
        ("Slate", Color(hex: "12141A")),
        ("Pure Black", .black)
    ]

    static let accentPresets: [(String, Color)] = [
        ("Violet", Color(hex: "7C5CFF")),
        ("Cyan", Color(hex: "00E5FF")),
        ("Pink", Color(hex: "FF2D95")),
        ("Lime", Color(hex: "B6FF3B")),
        ("Orange", Color(hex: "FF8A3D")),
        ("Gold", Color(hex: "FFD60A")),
        ("Blue", Color(hex: "3B82F6")),
        ("White", Color(hex: "F5F5F7"))
    ]

    static let joystickPresets: [(String, Color, Color)] = [
        ("Cyber", Color(hex: "1C1C24"), Color(hex: "00E5FF")),
        ("Xbox", Color(hex: "141414"), Color(hex: "107C10")),
        ("PlayStation", Color(hex: "16161E"), Color(hex: "0070D1")),
        ("Neon", Color(hex: "1A1018"), Color(hex: "FF2D95")),
        ("Gold", Color(hex: "1A1810"), Color(hex: "FFD60A")),
        ("Ice", Color(hex: "101820"), Color(hex: "A0E7FF"))
    ]

    init() {}
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
