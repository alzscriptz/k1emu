import Foundation
import Combine

@MainActor
final class ROMLibrary: ObservableObject {
    @Published var games: [GameItem] = []
    @Published var lastError: String?

    private let fm = FileManager.default

    private var documentsURL: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var libraryURL: URL {
        documentsURL.appendingPathComponent("library.json")
    }

    var romsDirectory: URL {
        let url = documentsURL.appendingPathComponent("ROMs", isDirectory: true)
        try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static let romExts: Set<String> = [
        "ch8", "c8", "nds", "dsi", "gba", "gb", "gbc", "nes", "fds",
        "sfc", "smc", "n64", "z64", "v64", "iso", "bin", "cue", "chd",
        "pbp", "md", "gen", "smd", "sms", "gg", "zip", "7z", "rar"
    ]

    init() {
        try? fm.createDirectory(at: romsDirectory, withIntermediateDirectories: true)
        load()
        seedDemoIfEmpty()
        scanDocumentsForROMs()
    }

    func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let decoded = try? JSONDecoder().decode([GameItem].self, from: data) else {
            games = []
            return
        }
        // Keep entries that still have files
        games = decoded.filter { $0.fileExists }
            .sorted { ($0.lastPlayed ?? $0.dateAdded) > ($1.lastPlayed ?? $1.dateAdded) }
        if games.count != decoded.count { save() }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(games) else { return }
        try? data.write(to: libraryURL, options: .atomic)
    }

    /// Copy from a security-scoped / picker URL into ROMs/. Returns the game or nil.
    @discardableResult
    func importFile(from source: URL, name: String?, system: String) -> GameItem? {
        lastError = nil

        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }

        let originalName = source.lastPathComponent
        let safeName = sanitize(originalName)
        let dest = romsDirectory.appendingPathComponent(safeName)

        do {
            // Remove existing dest if any
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }

            // Prefer NSFileCoordinator for iCloud / Files picks
            var coordError: NSError?
            var copyError: Error?
            let coordinator = NSFileCoordinator(filePresenter: nil)
            coordinator.coordinate(readingItemAt: source, options: [], error: &coordError) { readURL in
                do {
                    try self.fm.copyItem(at: readURL, to: dest)
                } catch {
                    // Fallback: Data read/write
                    do {
                        let data = try Data(contentsOf: readURL)
                        try data.write(to: dest, options: .atomic)
                    } catch {
                        copyError = error
                    }
                }
            }

            if let e = coordError {
                // Last resort without coordinator
                if !fm.fileExists(atPath: dest.path) {
                    let data = try Data(contentsOf: source)
                    try data.write(to: dest, options: .atomic)
                }
                _ = e
            }
            if let copyError {
                // try plain Data once more
                if !fm.fileExists(atPath: dest.path) {
                    let data = try Data(contentsOf: source)
                    try data.write(to: dest, options: .atomic)
                } else {
                    throw copyError
                }
            }

            guard fm.fileExists(atPath: dest.path) else {
                lastError = "Copy finished but file not found at destination"
                return nil
            }

            let display = (name?.isEmpty == false) ? name! : (safeName as NSString).deletingPathExtension
            let game = GameItem(name: display, system: system, fileName: safeName)

            // Replace existing same fileName
            games.removeAll { $0.fileName == safeName }
            games.insert(game, at: 0)
            save()
            return game
        } catch {
            lastError = "Import failed: \(error.localizedDescription)"
            return nil
        }
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
        fileName = sanitize(fileName)
        let dest = romsDirectory.appendingPathComponent(fileName)
        try data.write(to: dest, options: .atomic)
        let display = (name?.isEmpty == false) ? name! : (fileName as NSString).deletingPathExtension
        let game = GameItem(name: display, system: system, fileName: fileName)
        games.removeAll { $0.fileName == fileName }
        games.insert(game, at: 0)
        save()
        return game
    }

    /// Scan Documents + ROMs + Inbox for any ROM files and add missing ones.
    func scanDocumentsForROMs() {
        let roots = [
            romsDirectory,
            documentsURL,
            documentsURL.appendingPathComponent("Inbox", isDirectory: true)
        ]
        for root in roots {
            guard let files = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { continue }
            for file in files {
                let ext = file.pathExtension.lowercased()
                guard Self.romExts.contains(ext) else { continue }
                let name = file.lastPathComponent
                // Already in library?
                if games.contains(where: { $0.fileName == name }) { continue }

                // Ensure it's inside ROMs/
                let dest = romsDirectory.appendingPathComponent(name)
                if file.standardizedFileURL != dest.standardizedFileURL {
                    if !fm.fileExists(atPath: dest.path) {
                        try? fm.copyItem(at: file, to: dest)
                    }
                }
                guard fm.fileExists(atPath: dest.path) else { continue }

                let system = Self.detectSystem(ext: ext) ?? "Other"
                let game = GameItem(
                    name: (name as NSString).deletingPathExtension,
                    system: system,
                    fileName: name
                )
                games.insert(game, at: 0)
            }
        }
        save()
    }

    /// IBM Logo CHIP-8 demo so library is never empty and Run works offline.
    private func seedDemoIfEmpty() {
        let demoName = "IBM_Logo.ch8"
        let dest = romsDirectory.appendingPathComponent(demoName)
        if !fm.fileExists(atPath: dest.path) {
            let bytes: [UInt8] = [
                0x00, 0xE0, 0xA2, 0x2A, 0x60, 0x0C, 0x61, 0x08, 0xD0, 0x1F, 0x70, 0x09,
                0xA2, 0x39, 0xD0, 0x1F, 0xA2, 0x48, 0xD0, 0x1F, 0xA2, 0x57, 0xD0, 0x1F,
                0xA2, 0x66, 0xD0, 0x1F, 0xA2, 0x75, 0xD0, 0x1F, 0x12, 0x28, 0xFF, 0x00,
                0xFF, 0x00, 0x3C, 0x00, 0x3C, 0x00, 0x3C, 0x00, 0x3C, 0x00, 0xFF, 0x00,
                0xFF, 0xFF, 0x00, 0xFF, 0x00, 0x38, 0x00, 0x3F, 0x00, 0x3F, 0x00, 0x38,
                0x00, 0xFF, 0x00, 0xFF, 0x80, 0x00, 0xE0, 0x00, 0xE0, 0x00, 0x80, 0x00,
                0x80, 0x00, 0xE0, 0x00, 0xE0, 0x00, 0x80, 0xF8, 0x00, 0xFC, 0x00, 0x3E,
                0x00, 0x3F, 0x00, 0x3B, 0x00, 0x39, 0x00, 0xF8, 0x00, 0xF8, 0x03, 0x00,
                0x07, 0x00, 0x0F, 0x00, 0xBF, 0x00, 0xFB, 0x00, 0xF3, 0x00, 0xE3, 0x00,
                0x43, 0xE0, 0x00, 0xE0, 0x00, 0x80, 0x00, 0x80, 0x00, 0x80, 0x00, 0x80,
                0x00, 0xE0, 0x00, 0xE0
            ]
            try? Data(bytes).write(to: dest, options: .atomic)
        }
        if !games.contains(where: { $0.fileName == demoName }),
           fm.fileExists(atPath: dest.path) {
            let game = GameItem(name: "IBM Logo (demo)", system: "CHIP8", fileName: demoName)
            games.insert(game, at: 0)
            save()
        }
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
        case "ch8", "c8": return "CHIP8"
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
        default: return nil
        }
    }
}
