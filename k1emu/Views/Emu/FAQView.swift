import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [(String, String)] = [
        ("How do I add a ROM?",
         "Tap the + button in the top-right corner. You can either paste a direct download URL or choose a file from Files / other apps."),
        ("What systems are supported?",
         "The UI supports NES, SNES, N64, Game Boy, GBC, GBA, PS1, NDS, Genesis, Master System, PC Engine and more. Real cores will be plugged in progressively."),
        ("How do Tweaks work?",
         "Go to the Tweak tab to manage cheat/tweak files. Long-press any game → Tweaks to apply a saved tweak. You can also change the loaded tweak from the game Info sheet."),
        ("What is TV Mode?",
         "In Settings turn on ‘tvOS / External Display’. When your iPhone is connected to a TV, monitor or AirPlay, the game picture goes to the big screen and the phone becomes a full Xbox-style controller."),
        ("Controller buttons",
         "• Two Windows buttons = toggle Mouse Mode (blue Xbox-style outline appears).\n• Top-right picture button = Browser Mode (useful when sharing to TV – shows a browser + mini keyboard instead of the game).\n• Menu button = opens the in-game menu (Tweaks / Speed / Keybinds / Quit)."),
        ("Mouse Mode",
         "Activate with the two Windows buttons. Once active you get a pointer and can use the d-pad as arrows or touch. Tap the Windows buttons again (or twice) to deactivate."),
        ("Browser Mode",
         "When the phone is acting as controller and the game is on the TV, Browser Mode replaces the game view on the phone with a full browser + small on-screen keyboard. Perfect for quick searches or downloading without leaving the session."),
        ("Gameplay Speed",
         "Open the in-game menu (Menu button) → Speed. Choose 0.5×, 1×, 1.5× or 2×."),
        ("Liquid Glass",
         "On iOS 18+ (and future iOS 26+) the UI automatically uses the system liquid-glass / advanced material effects. On older versions it falls back to ultra-thin materials and custom gradients."),
        ("Colors",
         "Settings → Background & Joystick colors. Pick from the cool presets or use the color pickers.")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.0) { title, body in
                    Section(title) {
                        Text(body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
