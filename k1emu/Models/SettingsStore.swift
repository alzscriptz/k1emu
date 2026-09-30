import SwiftUI
import Combine
import UIKit

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
    @Published var backgroundColor: Color = Color(hex: "0B0B10") { didSet { persist() } }
    @Published var accentColor: Color = Color(hex: "7C5CFF") { didSet { persist() } }
    @Published var joystickColor: Color = Color(hex: "1C1C24") { didSet { persist() } }
    @Published var joystickAccent: Color = Color(hex: "00E5FF") { didSet { persist() } }
    @Published var backgroundEffect: BackgroundEffect = .liquid { didSet { persist() } }
    @Published var useLiquidGlass: Bool = true { didSet { persist() } }
    @Published var colorScheme: ColorScheme? = .dark { didSet { persist() } }
    @Published var showFPS: Bool = true { didSet { persist() } }
    @Published var target4KWhenStable: Bool = true { didSet { persist() } }
    @Published var tvModeEnabled: Bool = true { didSet { persist() } }
    @Published var autoEnterControllerOnExternalDisplay: Bool = true { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private let prefix = "k1emu.settings."

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

    init() {
        load()
    }

    func resetToDefaults() {
        backgroundColor = Color(hex: "0B0B10")
        accentColor = Color(hex: "7C5CFF")
        joystickColor = Color(hex: "1C1C24")
        joystickAccent = Color(hex: "00E5FF")
        backgroundEffect = .liquid
        useLiquidGlass = true
        colorScheme = .dark
        showFPS = true
        target4KWhenStable = true
        tvModeEnabled = true
        autoEnterControllerOnExternalDisplay = true
        persist()
    }

    private func load() {
        if let value = defaults.string(forKey: key("backgroundColor")) { backgroundColor = Color(hex: value) }
        if let value = defaults.string(forKey: key("accentColor")) { accentColor = Color(hex: value) }
        if let value = defaults.string(forKey: key("joystickColor")) { joystickColor = Color(hex: value) }
        if let value = defaults.string(forKey: key("joystickAccent")) { joystickAccent = Color(hex: value) }
        if let value = defaults.string(forKey: key("backgroundEffect")), let effect = BackgroundEffect(rawValue: value) { backgroundEffect = effect }
        if defaults.object(forKey: key("useLiquidGlass")) != nil { useLiquidGlass = defaults.bool(forKey: key("useLiquidGlass")) }
        if defaults.object(forKey: key("showFPS")) != nil { showFPS = defaults.bool(forKey: key("showFPS")) }
        if defaults.object(forKey: key("target4KWhenStable")) != nil { target4KWhenStable = defaults.bool(forKey: key("target4KWhenStable")) }
        if defaults.object(forKey: key("tvModeEnabled")) != nil { tvModeEnabled = defaults.bool(forKey: key("tvModeEnabled")) }
        if defaults.object(forKey: key("autoEnterControllerOnExternalDisplay")) != nil {
            autoEnterControllerOnExternalDisplay = defaults.bool(forKey: key("autoEnterControllerOnExternalDisplay"))
        }
        if let value = defaults.string(forKey: key("colorScheme")) {
            colorScheme = value == "light" ? .light : value == "system" ? nil : .dark
        }
    }

    private func persist() {
        defaults.set(hex(backgroundColor), forKey: key("backgroundColor"))
        defaults.set(hex(accentColor), forKey: key("accentColor"))
        defaults.set(hex(joystickColor), forKey: key("joystickColor"))
        defaults.set(hex(joystickAccent), forKey: key("joystickAccent"))
        defaults.set(backgroundEffect.rawValue, forKey: key("backgroundEffect"))
        defaults.set(useLiquidGlass, forKey: key("useLiquidGlass"))
        defaults.set(showFPS, forKey: key("showFPS"))
        defaults.set(target4KWhenStable, forKey: key("target4KWhenStable"))
        defaults.set(tvModeEnabled, forKey: key("tvModeEnabled"))
        defaults.set(autoEnterControllerOnExternalDisplay, forKey: key("autoEnterControllerOnExternalDisplay"))
        if let scheme = colorScheme {
            defaults.set(scheme == .light ? "light" : "dark", forKey: key("colorScheme"))
        } else {
            defaults.set("system", forKey: key("colorScheme"))
        }
    }

    private func key(_ name: String) -> String { prefix + name }

    private func hex(_ color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return "0B0B10" }
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
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
