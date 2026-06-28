import Foundation

enum NoteTextFormatter {
    static func appendingTranscript(_ transcript: String, to existingText: String) -> String {
        let trimmedExistingText = existingText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedExistingText.isEmpty else {
            return trimmedTranscript
        }

        guard !trimmedTranscript.isEmpty else {
            return trimmedExistingText
        }

        return "\(trimmedExistingText)\n\n\(trimmedTranscript)"
    }
}
