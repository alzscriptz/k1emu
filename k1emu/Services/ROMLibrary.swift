import Foundation
import Combine
import ZIPFoundation

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

    private let supportedROMExtensions: Set<String> = [
        "nds", "dsi", "gba", "gb", "gbc", "nes", "fds",
        "sfc", "smc", "n64", "z64", "v64", "iso", "bin",
        "cue", "chd", "pbp", "md", "gen", "smd", "sms", "gg", "pce"
    ]

    init() {
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let decoded = try? JSONDecoder().decode([GameItem].self, from: data) else { return }
        games = decoded.sorted { ($0.lastPlayed ?? $0.dateAdded) > ($1.lastPlayed ?? $1.dateAdded) }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(games) else { return }
        try? data.write(to: libraryURL, options: .atomic)
    }

    @discardableResult
    func addGame(name: String, system: String, fileName: String, sourceURL: URL?) -> GameItem {
        var destURL: URL?

        if let source = sourceURL {
            let dest = romsDirectory.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: dest)

            do {
                try fileManager.copyItem(at: source, to: dest)
                destURL = dest
            } catch {
                if let data = try? Data(contentsOf: source) {
                    try? data.write(to: dest, options: .atomic)
                    if fileManager.fileExists(atPath: dest.path) {
                        destURL = dest
                    }
                }
            }
        }

        let game = GameItem(name: name, system: system, fileName: fileName, fileURL: destURL)
        games.insert(game, at: 0)
        save()
        return game
    }

    /// Imports a ROM or a ZIP containing a ROM. ZIP files are unpacked into the
    /// app's ROMs directory and the actual ROM is what gets registered in the library.
    @discardableResult
    func importROM(from sourceURL: URL, name: String?, system: String) throws -> GameItem {
        let ext = sourceURL.pathExtension.lowercased()

        if ext == "zip" {
            return try importZIP(from: sourceURL, name: name, system: system)
        }

        let originalName = sourceURL.lastPathComponent
        let displayName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = displayName?.isEmpty == false
            ? displayName!
            : sourceURL.deletingPathExtension().lastPathComponent

        let game = addGame(
            name: finalName,
            system: system,
            fileName: originalName,
            sourceURL: sourceURL
        )

        guard game.fileURL != nil else {
            throw ROMImportError.copyFailed
        }

        return game
    }

    private func importZIP(from sourceURL: URL, name: String?, system: String) throws -> GameItem {
        guard let archive = Archive(url: sourceURL, accessMode: .read) else {
            throw ROMImportError.invalidArchive
        }

        let entries = archive.filter { entry in
            let path = entry.path
            let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
            return entry.type == .file && supportedROMExtensions.contains(ext)
        }

        guard let entry = entries.first else {
            throw ROMImportError.noROMInArchive
        }

        let fileName = URL(fileURLWithPath: entry.path).lastPathComponent
        let destination = romsDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: destination)
        try archive.extract(entry, to: destination)

        let detectedSystem = detectSystem(extension: destination.pathExtension) ?? system
        let finalName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let gameName = finalName?.isEmpty == false
            ? finalName!
            : destination.deletingPathExtension().lastPathComponent

        let game = GameItem(
            name: gameName,
            system: detectedSystem,
            fileName: fileName,
            fileURL: destination
        )

        games.insert(game, at: 0)
        save()
        return game
    }

    func addFromURL(_ urlString: String, name: String?, system: String) async throws -> GameItem {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let temp = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(url.pathExtension.isEmpty ? "bin" : url.pathExtension)

        try data.write(to: temp, options: .atomic)
        defer { try? fileManager.removeItem(at: temp) }

        return try importROM(from: temp, name: name, system: system)
    }

    private func detectSystem(extension ext: String) -> String? {
        switch ext.lowercased() {
        case "nds", "dsi": return "NDS"
        case "gba": return "GBA"
        case "gb": return "GB"
        case "gbc": return "GBC"
        case "nes", "fds": return "NES"
        case "sfc", "smc": return "SNES"
        case "n64", "z64", "v64": return "N64"
        case "iso", "bin", "cue", "chd", "pbp": return "PS1"
        case "md", "gen", "smd": return "Genesis"
        case "sms", "gg": return "SMS"
        case "pce": return "PCE"
        default: return nil
        }
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

enum ROMImportError: LocalizedError {
    case copyFailed
    case invalidArchive
    case noROMInArchive

    var errorDescription: String? {
        switch self {
        case .copyFailed:
            return "k1emu could not copy this file into its ROM library."
        case .invalidArchive:
            return "That ZIP file could not be opened."
        case .noROMInArchive:
            return "That ZIP does not contain a supported ROM."
        }
    }
}
