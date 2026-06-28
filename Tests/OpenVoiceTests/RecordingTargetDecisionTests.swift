import Foundation
import Testing
@testable import OpenVoice

struct RecordingTargetDecisionTests {
    @Test
    func globallyStartedRecordingCreatesNewNote() {
        let destination = RecordingTargetDecision.destination(
            for: .global,
            stoppedBy: .globalButton
        )

        #expect(destination == .newNote)
    }

    @Test
    func noteStartedRecordingAppendsToOriginalNote() {
        let noteID = UUID()

        let destination = RecordingTargetDecision.destination(
            for: .note(noteID),
            stoppedBy: .noteButton(noteID)
        )

        #expect(destination == .existingNote(noteID))
    }

    @Test
    func stopSourceDoesNotAffectDestination() {
        let noteID = UUID()
        let otherNoteID = UUID()

        let destination = RecordingTargetDecision.destination(
            for: .note(noteID),
            stoppedBy: .noteButton(otherNoteID)
        )

        #expect(destination == .existingNote(noteID))
    }

    @Test
    func noteStartedRecordingStoppedFromGlobalButtonAppendsToOriginalNote() {
        let noteID = UUID()

        let destination = RecordingTargetDecision.destination(
            for: .note(noteID),
            stoppedBy: .globalButton
        )

        #expect(destination == .existingNote(noteID))
    }

    @Test
    func smartStopPreservesRecordingDestination() {
        let noteID = UUID()

        let destination = RecordingTargetDecision.destination(
            for: .note(noteID),
            stoppedBy: .smartStop
        )

        #expect(destination == .existingNote(noteID))
    }
}
