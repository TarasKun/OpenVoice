import Foundation
import SwiftData

@Model
final class TranscriptionItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var text: String

    init(id: UUID = UUID(), timestamp: Date = .now, text: String) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
    }
}
