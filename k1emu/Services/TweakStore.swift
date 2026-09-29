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

    init() {
        load()
        if tweaks.isEmpty {
            tweaks = [
                TweakItem(name: "Infinite Lives", description: "Never lose a life", system: "All", fileName: "inf_lives.cht"),
                TweakItem(name: "Max Speed", description: "Boost movement speed", system: "N64", fileName: "max_speed.cht"),
                TweakItem(name: "Unlock All", description: "All levels unlocked", system: "All", fileName: "unlock.cht")
            ]
            save()
        }
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
        tweaks.removeAll { $0.id == tweak.id }
        save()
    }
}
