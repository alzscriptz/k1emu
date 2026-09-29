import Foundation
import Combine

@MainActor
final class TweakStore: ObservableObject {
    @Published var tweaks: [TweakItem] = []

    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var storeURL: URL {
        documentsURL.appendingPathComponent("tweaks.json")
    }

    /// Built-in preset tweaks always available
    static let presets: [TweakItem] = [
        TweakItem(name: "Infinite Lives", description: "Never lose a life", system: "All", fileName: "preset_inf_lives.cht"),
        TweakItem(name: "Infinite Health", description: "HP never drops", system: "All", fileName: "preset_inf_hp.cht"),
        TweakItem(name: "Max Money / Score", description: "Resources maxed", system: "All", fileName: "preset_money.cht"),
        TweakItem(name: "Unlock All Levels", description: "Every stage available", system: "All", fileName: "preset_unlock.cht"),
        TweakItem(name: "Moon Jump", description: "Hold jump for float", system: "N64", fileName: "preset_moon.cht"),
        TweakItem(name: "Walk Through Walls", description: "No collision", system: "All", fileName: "preset_noclip.cht"),
        TweakItem(name: "One-Hit KO", description: "Enemies die in one hit", system: "All", fileName: "preset_ohko.cht"),
        TweakItem(name: "Fast Forward Always", description: "Game runs 2× internally", system: "All", fileName: "preset_ff.cht"),
        TweakItem(name: "Invincibility", description: "No damage taken", system: "All", fileName: "preset_invuln.cht"),
        TweakItem(name: "All Items", description: "Inventory full", system: "All", fileName: "preset_items.cht")
    ]

    init() {
        load()
        // Ensure presets exist
        for p in Self.presets {
            if !tweaks.contains(where: { $0.fileName == p.fileName }) {
                tweaks.append(p)
            }
        }
        save()
    }

    func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([TweakItem].self, from: data) else { return }
        tweaks = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(tweaks) else { return }
        try? data.write(to: storeURL)
    }

    func add(_ tweak: TweakItem) {
        tweaks.insert(tweak, at: 0)
        save()
    }

    func delete(_ tweak: TweakItem) {
        // Don't delete built-in presets from disk identity — allow remove from list only if custom
        if Self.presets.contains(where: { $0.fileName == tweak.fileName }) { return }
        tweaks.removeAll { $0.id == tweak.id }
        save()
    }

    var customTweaks: [TweakItem] {
        tweaks.filter { t in !Self.presets.contains(where: { $0.fileName == t.fileName }) }
    }

    var presetTweaks: [TweakItem] {
        tweaks.filter { t in Self.presets.contains(where: { $0.fileName == t.fileName }) }
    }
}
