import Foundation
import Combine

@MainActor
final class ROMLibrary: ObservableObject {
    @Published var games: [GameItem] = []
    @Published var lastError: String?

    private let fm = FileManager.default
    private let libraryURL: URL
    private let romsDirectory: URL

    init() {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        libraryURL = docs.appendingPathComponent("library.json")
        romsDirectory = docs.appendingPathComponent("ROMs", isDirectory: true)
        try? fm.createDirectory(at: romsDirectory, withIntermediateDirectories: true)
        try? fm.removeItem(at: romsDirectory.appendingPathComponent("IBM_Logo.ch8"))
        load()
        scanDocumentsForROMs()
    }

    func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let decoded = try? JSONDecoder().decode([GameItem].self, from: data) else {
            games = []
            return
        }
        games = decoded.filter { $0.fileExists && $0.fileName != "IBM_Logo.ch8" }
        if games.count != decoded.count { save() }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(games) else { return }
        try? data.write(to: libraryURL, options: .atomic)
    }

    @discardableResult
    func importFile(from source: URL, name: String?, system: String) -> GameItem? {
        lastError = nil
        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }

        var result: GameItem?
        var coordError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: source, options: [], error: &coordError) { readURL in
            result = self.copyImported(readURL, name: name, system: system)
        }
        if let coordError {
            lastError = coordError.localizedDescription
        }
        return result
    }

    private func copyImported(_ url: URL, name: String?, system: String) -> GameItem? {
        let safeName = sanitize(url.lastPathComponent)
        let dest = romsDirectory.appendingPathComponent(safeName)
        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: url, to: dest)
            let display = name?.isEmpty == false ? name! : url.deletingPathExtension().lastPathComponent
            let sys = system.isEmpty ? (Self.detectSystem(ext: url.pathExtension) ?? "UNKNOWN") : system
            let game = GameItem(name: display, system: sys, fileName: safeName)
            games.removeAll { $0.fileName == safeName }
            games.insert(game, at: 0)
            save()
            return game
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func addFromURL(_ urlString: String, name: String?, system: String) async throws -> GameItem {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ROMLibrary", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad URL"])
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let fileName = sanitize(url.lastPathComponent)
        let dest = romsDirectory.appendingPathComponent(fileName)
        try data.write(to: dest)
        let display = name?.isEmpty == false ? name! : url.deletingPathExtension().lastPathComponent
        let sys = system.isEmpty ? (Self.detectSystem(ext: url.pathExtension) ?? "UNKNOWN") : system
        let game = GameItem(name: display, system: sys, fileName: fileName)
        await MainActor.run {
            self.games.removeAll { $0.fileName == fileName }
            self.games.insert(game, at: 0)
            self.save()
        }
        return game
    }

    func scanDocumentsForROMs() {
        guard let files = try? fm.contentsOfDirectory(at: romsDirectory, includingPropertiesForKeys: nil) else { return }
        var changed = false
        for file in files {
            let name = file.lastPathComponent
            if name == "IBM_Logo.ch8" {
                try? fm.removeItem(at: file)
                continue
            }
            let ext = file.pathExtension.lowercased()
            guard Self.detectSystem(ext: ext) != nil || ["zip", "7z", "rar"].contains(ext) else { continue }
            if games.contains(where: { $0.fileName == name }) { continue }
            let system = Self.detectSystem(ext: ext) ?? "UNKNOWN"
            let title = file.deletingPathExtension().lastPathComponent
            games.insert(GameItem(name: title, system: system, fileName: name), at: 0)
            changed = true
        }
        games.removeAll { $0.fileName == "IBM_Logo.ch8" || !$0.fileExists }
        if changed { save() }
    }

    func markPlayed(_ game: GameItem) {
        guard let idx = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[idx].lastPlayed = Date()
        games[idx].playCount += 1
        save()
    }

    func delete(_ game: GameItem) {
        try? fm.removeItem(at: game.fileURL)
        games.removeAll { $0.id == game.id }
        save()
    }

    func update(_ game: GameItem) {
        if let idx = games.firstIndex(where: { $0.id == game.id }) {
            games[idx] = game
            save()
        }
    }

    private func sanitize(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        return name.components(separatedBy: invalid).joined(separator: "_")
    }

    static func detectSystem(ext: String) -> String? {
        switch ext.lowercased() {
        case "nds", "dsi": return "NDS"
        case "gba": return "GBA"
        case "gb", "gbc": return "GB"
        case "nes", "fds": return "NES"
        case "sfc", "smc": return "SNES"
        case "n64", "z64", "v64": return "N64"
        case "ch8", "c8": return "CHIP8"
        case "md", "gen", "smd": return "GEN"
        case "sms", "gg": return "SMS"
        case "iso", "bin", "cue", "chd", "pbp": return "DISC"
        default: return nil
        }
    }
}
