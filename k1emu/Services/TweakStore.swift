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

    private var tweakDirectory: URL {
        let url = documentsURL.appendingPathComponent("Tweaks", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Presets are real tweak files. Their payload is intentionally a safe
    /// template because cheat addresses are game-specific; imported game codes
    /// are stored and selectable without inventing a working code.
    static let presets: [TweakItem] = [
        TweakItem(name: "Infinite Lives", description: "Game-specific cheat template", system: "All", fileName: "infinite_lives.cht", content: "# k1emu cheat preset\n# Add the game's code below.\n"),
        TweakItem(name: "Infinite Health", description: "Game-specific cheat template", system: "All", fileName: "infinite_health.cht", content: "# k1emu cheat preset\n# Add the game's code below.\n"),
        TweakItem(name: "Max Money / Score", description: "Game-specific value template", system: "All", fileName: "max_money_score.cht", content: "# k1emu cheat preset\n# Add the game's code below.\n"),
        TweakItem(name: "Unlock All Levels", description: "Game-specific unlock template", system: "All", fileName: "unlock_all_levels.cht", content: "# k1emu cheat preset\n# Add the game's code below.\n"),
        TweakItem(name: "Moon Jump", description: "Game-specific movement template", system: "N64", fileName: "moon_jump.cht", content: "# k1emu cheat preset\n# Add the game's code below.\n"),
        TweakItem(name: "Walk Through Walls", description: "Game-specific collision template", system: "All", fileName: "walk_through_walls.cht", content: "# k1emu cheat preset\n# Add the game's code below.\n"),
        TweakItem(name: "One-Hit KO", description: "Game-specific damage template", system: "All", fileName: "one_hit_ko.cht", content: "# k1emu cheat preset\n# Add the game's code below.\n"),
        TweakItem(name: "Invincibility", description: "Game-specific damage template", system: "All", fileName: "invincibility.cht", content: "# k1emu cheat preset\n# Add the game's code below.\n")
    ]

    init() {
        load()
        for preset in Self.presets {
            if !tweaks.contains(where: { $0.fileName == preset.fileName }) {
                tweaks.append(preset)
            }
            writeFile(for: preset)
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
        try? data.write(to: storeURL, options: .atomic)
    }

    func add(_ tweak: TweakItem) {
        tweaks.insert(tweak, at: 0)
        writeFile(for: tweak)
        save()
    }

    func update(_ tweak: TweakItem) {
        guard let index = tweaks.firstIndex(where: { $0.id == tweak.id }) else { return }
        tweaks[index] = tweak
        writeFile(for: tweak)
        save()
    }

    func delete(_ tweak: TweakItem) {
        if Self.presets.contains(where: { $0.fileName == tweak.fileName }) { return }
        try? fileManager.removeItem(at: tweakDirectory.appendingPathComponent(tweak.fileName))
        tweaks.removeAll { $0.id == tweak.id }
        save()
    }

    func fileURL(for tweak: TweakItem) -> URL {
        tweakDirectory.appendingPathComponent(tweak.fileName)
    }

    private func writeFile(for tweak: TweakItem) {
        guard let data = tweak.content.data(using: .utf8) else { return }
        try? data.write(to: fileURL(for: tweak), options: .atomic)
    }

    var customTweaks: [TweakItem] {
        tweaks.filter { t in !Self.presets.contains(where: { $0.fileName == t.fileName }) }
    }

    var presetTweaks: [TweakItem] {
        tweaks.filter { t in Self.presets.contains(where: { $0.fileName == t.fileName }) }
    }
}
