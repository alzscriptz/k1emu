import Foundation
import Combine

@MainActor
final class ROMLibrary: ObservableObject {
    @Published var games: [GameItem] = []

    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var libraryURL: URL {
        documentsURL.appendingPathComponent("library.json")
    }

    private var romsDirectory: URL {
        let url = documentsURL.appendingPathComponent("ROMs", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    init() {
        load()
        // Empty by default — only show what the user adds
    }

    func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let decoded = try? JSONDecoder().decode([GameItem].self, from: data) else { return }
        games = decoded.sorted { ($0.lastPlayed ?? $0.dateAdded) > ($1.lastPlayed ?? $1.dateAdded) }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(games) else { return }
        try? data.write(to: libraryURL)
    }

    func addGame(name: String, system: String, fileName: String, sourceURL: URL?) -> GameItem {
        var destURL: URL? = nil
        if let source = sourceURL {
            let dest = romsDirectory.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: dest)
            do {
                try fileManager.copyItem(at: source, to: dest)
                destURL = dest
            } catch {
                // Fallback: try reading data and writing
                if let data = try? Data(contentsOf: source) {
                    try? data.write(to: dest)
                    destURL = dest
                }
            }
        }
        let game = GameItem(name: name, system: system, fileName: fileName, fileURL: destURL)
        games.insert(game, at: 0)
        save()
        return game
    }

    func addFromURL(_ urlString: String, name: String?, system: String) async throws -> GameItem {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let fileName = url.lastPathComponent.isEmpty ? "rom_\(UUID().uuidString).bin" : url.lastPathComponent
        let dest = romsDirectory.appendingPathComponent(fileName)
        try data.write(to: dest)
        let finalName = name?.isEmpty == false ? name! : fileName
        return addGame(name: finalName, system: system, fileName: fileName, sourceURL: nil)
    }

    func delete(_ game: GameItem) {
        if let fileURL = game.fileURL {
            try? fileManager.removeItem(at: fileURL)
        }
        games.removeAll { $0.id == game.id }
        save()
    }

    func update(_ game: GameItem) {
        if let idx = games.firstIndex(where: { $0.id == game.id }) {
            games[idx] = game
            save()
        }
    }
}
