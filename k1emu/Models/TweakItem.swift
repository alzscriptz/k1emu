import Foundation

struct TweakItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var system: String
    var fileName: String
    var content: String
    var dateAdded: Date
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        system: String = "All",
        fileName: String,
        content: String = "",
        dateAdded: Date = Date(),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.system = system
        self.fileName = fileName
        self.content = content
        self.dateAdded = dateAdded
        self.isEnabled = isEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, system, fileName, content, dateAdded, isEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        system = try c.decodeIfPresent(String.self, forKey: .system) ?? "All"
        fileName = try c.decode(String.self, forKey: .fileName)
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        dateAdded = try c.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
}
