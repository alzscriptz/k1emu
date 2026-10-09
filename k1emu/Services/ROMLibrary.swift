import Foundation
import UIKit

/// ROM library: scan Documents/ROMs, import via document picker, persist metadata.
final class ROMLibrary: ObservableObject {
    static let shared = ROMLibrary()

    @Published var games: [GameItem] = []
    @Published var lastError: String?

    private let fm = FileManager.default

    var documentsURL: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var romsDirectory: URL {
        documentsURL.appendingPathComponent("ROMs", isDirectory: true)
    }

    private var libraryURL: URL {
        documentsURL.appendingPathComponent("library.json")
    }

    private let knownExt: Set<String> = [
        "ch8", "c8", "nds", "dsi", "gba", "gb", "gbc", "nes", "fds",
        "sfc", "smc", "n64", "z64", "v64", "iso", "bin", "cue", "chd",
        "pbp", "md", "gen", "smd", "sms", "gg", "zip", "7z", "rar"
    ]

    init() {
        try? fm.createDirectory(at: romsDirectory, withIntermediateDirectories: true)
        // Wipe old IBM demo if present
        let ibm = romsDirectory.appendingPathComponent("IBM_Logo.ch8")
        try? fm.removeItem(at: ibm)
        load()
        scanDocumentsForROMs()
    }

    func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let decoded = try? JSONDecoder().decode([GameItem].self, from: data) else {
            games = []
            return
        }
        games = decoded
            .filter { $0.fileExists && $0.fileName != "IBM_Logo.ch8" }
            .sorted { ($0.lastPlayed ?? $0.dateAdded) > ($1.lastPlayed ?? $1.dateAdded) }
        if games.count != decoded.count { save() }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(games) else { return }
        try? data.write(to: libraryURL, options: .atomic)
    }

    @discardableResult
    func addFromURL(_ url: URL) -> GameItem? {
        lastError = nil
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        var coordError: NSError?
        var result: GameItem?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordError) { readURL in
            result = self.copyIn(readURL)
        }
        if let coordError {
            lastError = coordError.localizedDescription
            return nil
        }
        return result
    }

    private func copyIn(_ url: URL) -> GameItem? {
        let ext = url.pathExtension.lowercased()
        guard knownExt.contains(ext) else {
            lastError = "Unsupported file type .\(ext)"
            return nil
        }
        let safeName = sanitize(url.lastPathComponent)
        let dest = romsDirectory.appendingPathComponent(safeName)
        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: url, to: dest)
            let system = Self.detectSystem(ext: ext) ?? "UNKNOWN"
            let name = url.deletingPathExtension().lastPathComponent
            let game = GameItem(name: name, system: system, fileName: safeName)
            games.removeAll { $0.fileName == safeName }
            games.insert(game, at: 0)
            save()
            return game
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func scanDocumentsForROMs() {
        guard let files = try? fm.contentsOfDirectory(
            at: romsDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        var changed = false
        for file in files {
            let name = file.lastPathComponent
            if name == "IBM_Logo.ch8" {
                try? fm.removeItem(at: file)
                continue
            }
            let ext = file.pathExtension.lowercased()
            guard knownExt.contains(ext) else { continue }
            if games.contains(where: { $0.fileName == name }) { continue }
            let system = Self.detectSystem(ext: ext) ?? "UNKNOWN"
            let title = file.deletingPathExtension().lastPathComponent
            let game = GameItem(name: title, system: system, fileName: name)
            games.insert(game, at: 0)
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
