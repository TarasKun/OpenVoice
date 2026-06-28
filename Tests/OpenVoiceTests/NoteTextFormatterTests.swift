import Testing
@testable import OpenVoice

struct NoteTextFormatterTests {
    @Test
    func appendingTranscriptToEmptyNoteReturnsTranscript() {
        #expect(NoteTextFormatter.appendingTranscript("Hello world", to: "") == "Hello world")
    }

    @Test
    func appendingTranscriptToExistingNoteSeparatesWithBlankLine() {
        let result = NoteTextFormatter.appendingTranscript("Second paragraph", to: "First paragraph")

        #expect(result == "First paragraph\n\nSecond paragraph")
    }
}
