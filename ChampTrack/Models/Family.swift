import Foundation

struct Family: Identifiable, Codable {
    let id: String
    var name: String
    var createdBy: String
    var members: [String]
    var children: [String]
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        createdBy: String,
        members: [String] = [],
        children: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.members = members
        self.children = children
        self.createdAt = createdAt
    }
}
