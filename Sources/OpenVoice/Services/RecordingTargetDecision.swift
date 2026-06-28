import Foundation

enum RecordingStartTarget: Equatable {
    case global
    case note(UUID)
}

enum RecordingStopSource: Equatable {
    case globalButton
    case noteButton(UUID)
    case smartStop
}

enum TranscriptionSaveDestination: Equatable {
    case newNote
    case existingNote(UUID)
}

enum RecordingTargetDecision {
    static func destination(
        for startTarget: RecordingStartTarget,
        stoppedBy _: RecordingStopSource
    ) -> TranscriptionSaveDestination {
        switch startTarget {
        case .global:
            .newNote
        case .note(let id):
            .existingNote(id)
        }
    }
}
