import Foundation

final class ROMLibrary: ObservableObject {
    static let shared = ROMLibrary()

    @Published private(set) var games: [GameItem] = []

    private var romsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ROMs", isDirectory: true)
    }

    init() {
        try? FileManager.default.createDirectory(at: romsDir, withIntermediateDirectories: true)
        refresh()
    }

    func refresh() {
        var items: [GameItem] = []
        guard let files = try? FileManager.default.contentsOfDirectory(at: romsDir, includingPropertiesForKeys: nil) else {
            games = []
            return
        }
        for url in files {
            let ext = url.pathExtension.lowercased()
            guard Self.detectSystem(ext: ext) != nil || ["zip", "7z", "rar"].contains(ext) else { continue }
            let name = url.deletingPathExtension().lastPathComponent
            let system = Self.detectSystem(ext: ext) ?? "UNKNOWN"
            items.append(GameItem(name: name, system: system, fileName: url.lastPathComponent))
        }
        games = items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func importFile(from source: URL, name: String?, system: String) -> GameItem? {
        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }
        var readURL = source
        var coordinatorError: NSError?
        let coordinator = NSFileCoordinator()
        var result: GameItem?
        coordinator.coordinate(readingItemAt: source, options: [], error: &coordinatorError) { url in
            readURL = url
            result = self.copyImported(readURL, name: name, system: system)
        }
        if result == nil, coordinatorError == nil {
            result = copyImported(source, name: name, system: system)
        }
        refresh()
        return result
    }

    private func copyImported(_ url: URL, name: String?, system: String) -> GameItem? {
        do {
            let safeName = url.lastPathComponent
            let dest = romsDir.appendingPathComponent(safeName)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: url, to: dest)
            let display = name ?? url.deletingPathExtension().lastPathComponent
            let sys = system.isEmpty ? (Self.detectSystem(ext: url.pathExtension) ?? "UNKNOWN") : system
            let game = GameItem(name: display, system: sys, fileName: safeName)
            return game
        } catch {
            return nil
        }
    }

    func addFromURL(_ urlString: String, name: String?, system: String) async throws -> GameItem {
        guard let remote = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: remote)
        let fileName = remote.lastPathComponent.isEmpty ? "rom.bin" : remote.lastPathComponent
        let dest = romsDir.appendingPathComponent(fileName)
        try data.write(to: dest)
        let display = name ?? remote.deletingPathExtension().lastPathComponent
        let sys = system.isEmpty ? (Self.detectSystem(ext: remote.pathExtension) ?? "UNKNOWN") : system
        let game = GameItem(name: display, system: sys, fileName: fileName)
        await MainActor.run { refresh() }
        return game
    }

    func delete(_ game: GameItem) {
        let url = romsDir.appendingPathComponent(game.fileName)
        try? FileManager.default.removeItem(at: url)
        refresh()
    }

    func path(for game: GameItem) -> URL {
        romsDir.appendingPathComponent(game.fileName)
    }

    static func detectSystem(ext: String) -> String? {
        switch ext.lowercased() {
        case "nds", "dsi", "ids": return "NDS"
        case "gba": return "GBA"
        case "gb": return "GB"
        case "gbc": return "GBC"
        case "nes", "fds", "unf": return "NES"
        case "sfc", "smc": return "SNES"
        case "n64", "z64", "v64": return "N64"
        case "ch8", "c8": return "CHIP8"
        case "md", "gen", "smd": return "Genesis"
        case "sms", "gg": return "SMS"
        case "cue", "pbp", "chd": return "PS1"
        case "iso", "cso": return "PSP"
        case "gcm", "gcz", "tgc": return "GC"
        case "wbfs", "wad", "rvz", "wia": return "WII"
        case "gdi", "cdi": return "DC"
        case "vb": return "VB"
        case "ws", "wsc": return "WS"
        case "min": return "POKEMINI"
        default: return nil
        }
    }
}
