# Testing Plan

OpenVoice currently has no Swift Package test target. Add tests before refactoring production code.

## Testing Order

1. Add Swift Package test target / make minimal logic importable.
2. Add pure tests for note append formatting.
3. Add pure tests for recording target/save decision logic.
4. Add tests for note-targeted recording stopped from global stop button.
5. Add tests for smart stop preserving recording target.
6. Add model persistence/fallback tests later.
7. Add SwiftData integration tests later.
8. Add UI-ish tests for `HistoryView` only after logic is separated.

## Behaviors To Protect First

- Global recording creates a new note.
- Note-targeted recording appends to the original note.
- Stopping note-targeted recording from the global bottom stop button still appends to the original note.
- Smart stop uses the same recording target selected at recording start.
- Note append formatting preserves existing text and separates appended transcript blocks.
- Selected Whisper model persists across reload/app launch.
- Deleted selected model falls back to a valid downloaded model.
- No active/downloaded model means record controls are unavailable.

## Recommended First Test Diff

- Add a test target in `Package.swift`.
- Add tiny pure helpers only where needed for tests.
- Start with tests for append formatting and recording target/save decisions.
- Do not rewrite views or services in the first test diff.

## Do Not Test First

- `HistoryView` sticky icon positioning.
- AppKit `NSTextView` behavior.
- AVFoundation microphone integration.
- Real Hugging Face downloads.
- Real `whisper-cli` process execution.

Those areas need seams first; protect pure product logic before touching them.

