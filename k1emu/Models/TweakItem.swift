import Foundation

struct TweakItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var system: String          // which systems it applies to (or "All")
    var fileName: String
    var dateAdded: Date
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        system: String = "All",
        fileName: String,
        dateAdded: Date = Date(),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.system = system
        self.fileName = fileName
        self.dateAdded = dateAdded
        self.isEnabled = isEnabled
    }
}
