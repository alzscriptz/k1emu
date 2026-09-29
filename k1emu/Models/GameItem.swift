import Foundation

struct GameItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var system: String          // NES, SNES, N64, PS1, GB, GBA, etc.
    var fileName: String
    var fileURL: URL?
    var coverURL: URL?
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
        fileURL: URL? = nil,
        coverURL: URL? = nil,
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
        self.fileURL = fileURL
        self.coverURL = coverURL
        self.dateAdded = dateAdded
        self.lastPlayed = lastPlayed
        self.playCount = playCount
        self.notes = notes
        self.appliedTweakID = appliedTweakID
    }

    var displaySystem: String {
        system.uppercased()
    }
}
