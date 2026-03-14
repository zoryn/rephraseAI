import Foundation

struct Mode: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var prompt: String

    init(id: UUID = UUID(), title: String = "New Mode", prompt: String = "") {
        self.id = id
        self.title = title
        self.prompt = prompt
    }
}
