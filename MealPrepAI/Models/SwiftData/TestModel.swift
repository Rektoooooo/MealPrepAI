import Foundation
import SwiftData

@Model
final class TestModel {
    var id: UUID
    var name: String
    var createdAt: Date

    init(name: String = "Test") {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
