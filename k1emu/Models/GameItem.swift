import Foundation

struct GameItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var system: String
    /// Filename only inside Documents/ROMs (stable across relaunches)
    var fileName: String
    var dateAdded: Date
    var lastPlayed: Date?
    var playCount: Int
    var notes: String
    var appliedTweakID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        system: String,
        fileName: String,
        dateAdded: Date = Date(),
        lastPlayed: Date? = nil,
        playCount: Int = 0,
        notes: String = "",
        appliedTweakID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.system = system
        self.fileName = fileName
        self.dateAdded = dateAdded
        self.lastPlayed = lastPlayed
        self.playCount = playCount
        self.notes = notes
        self.appliedTweakID = appliedTweakID
    }

    var displaySystem: String { system.uppercased() }

    /// Resolved absolute path in Documents/ROMs
    var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("ROMs", isDirectory: true).appendingPathComponent(fileName)
    }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
}
