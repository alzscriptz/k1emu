import Foundation
import Combine

@MainActor
final class ROMLibrary: ObservableObject {
    @Published var games: [GameItem] = []
    @Published var lastError: String?

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
    }

    func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let decoded = try? JSONDecoder().decode([GameItem].self, from: data) else {
            games = []
            return
        }
        // Drop entries whose file is gone
        games = decoded.filter { game in
            guard let url = game.fileURL else { return false }
            return fileManager.fileExists(atPath: url.path)
        }.sorted { ($0.lastPlayed ?? $0.dateAdded) > ($1.lastPlayed ?? $1.dateAdded) }
        if games.count != decoded.count { save() }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(games) else { return }
        try? data.write(to: libraryURL, options: .atomic)
    }

    /// Copy a user-picked file (including .zip) into the app ROMs folder.
    @discardableResult
    func addGame(name: String, system: String, fileName: String, sourceURL: URL?) -> GameItem {
        lastError = nil
        var destURL: URL? = nil

        if let source = sourceURL {
            let safeName = sanitizeFileName(fileName)
            let dest = romsDirectory.appendingPathComponent(safeName)

            // Security-scoped access for Files app / iCloud picks
            let accessed = source.startAccessingSecurityScopedResource()
            defer { if accessed { source.stopAccessingSecurityScopedResource() } }

            try? fileManager.removeItem(at: dest)

            do {
                // Prefer coordinated copy for iCloud / Files
                try fileManager.copyItem(at: source, to: dest)
                destURL = dest
            } catch {
                // Fallback: read bytes then write (works for many providers)
                do {
                    let data = try Data(contentsOf: source)
                    try data.write(to: dest, options: .atomic)
                    destURL = dest
                } catch {
                    lastError = "Could not copy ROM: \(error.localizedDescription)"
                }
            }
        }

        let game = GameItem(
            name: name,
            system: system,
            fileName: destURL?.lastPathComponent ?? fileName,
            fileURL: destURL
        )
        games.insert(game, at: 0)
        save()
        return game
    }

    func addFromURL(_ urlString: String, name: String?, system: String) async throws -> GameItem {
        lastError = nil
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        var fileName = url.lastPathComponent
        if fileName.isEmpty || !fileName.contains(".") {
            fileName = "rom_\(UUID().uuidString).bin"
        }
        fileName = sanitizeFileName(fileName)
        let dest = romsDirectory.appendingPathComponent(fileName)
        try data.write(to: dest, options: .atomic)
        let finalName = (name?.isEmpty == false) ? name! : (fileName as NSString).deletingPathExtension
        return addGame(name: finalName, system: system, fileName: fileName, sourceURL: nil)
            .withFileURL(dest)
    }

    func markPlayed(_ game: GameItem) {
        guard let idx = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[idx].lastPlayed = Date()
        games[idx].playCount += 1
        save()
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

    private func sanitizeFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        return name.components(separatedBy: invalid).joined(separator: "_")
    }
}

private extension GameItem {
    func withFileURL(_ url: URL) -> GameItem {
        var g = self
        g.fileURL = url
        return g
    }
}
