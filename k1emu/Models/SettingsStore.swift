import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    // MARK: - Appearance
    @Published var backgroundColor: Color = Color(hex: "0F0F12")
    @Published var accentColor: Color = Color(hex: "7C5CFF")
    @Published var joystickColor: Color = Color(hex: "2A2A32")
    @Published var joystickAccent: Color = Color(hex: "00D4FF")
    @Published var useLiquidGlass: Bool = true
    @Published var colorScheme: ColorScheme? = .dark

    // MARK: - TV / Controller
    @Published var tvModeEnabled: Bool = true
    @Published var autoEnterControllerOnExternalDisplay: Bool = true

    // MARK: - Presets
    static let backgroundPresets: [(String, Color)] = [
        ("Deep Black", Color(hex: "0F0F12")),
        ("Midnight", Color(hex: "12121A")),
        ("Ocean", Color(hex: "0A1628")),
        ("Forest", Color(hex: "0D1A12")),
        ("Purple Night", Color(hex: "1A0F2E")),
        ("Crimson", Color(hex: "1A0A0A")),
        ("Slate", Color(hex: "1C1C24")),
        ("Pure Black", .black)
    ]

    static let joystickPresets: [(String, Color, Color)] = [
        ("Cyber", Color(hex: "2A2A32"), Color(hex: "00D4FF")),
        ("Xbox Green", Color(hex: "1A1A1A"), Color(hex: "107C10")),
        ("PlayStation", Color(hex: "1E1E24"), Color(hex: "003791")),
        ("Neon Pink", Color(hex: "2A1A24"), Color(hex: "FF2D95")),
        ("Gold", Color(hex: "2A2418"), Color(hex: "FFD700")),
        ("Ice", Color(hex: "1A2228"), Color(hex: "A0E7FF"))
    ]

    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func load() {
        // Simple persistence – expand later if needed
        if let data = defaults.data(forKey: "bgColor"),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            backgroundColor = Color(color)
        }
    }

    func save() {
        // Persist key colors
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
