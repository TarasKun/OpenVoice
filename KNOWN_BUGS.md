# Known Bugs And Fragile Areas

## Current Known Issues

- No automated tests exist yet.
- `.vscode/` may appear as an untracked local folder; it is not part of the app.

## Fragile Areas

- `MainMenuView.swift` is high risk because it owns recording target routing and transcription save behavior.
- `HistoryView.swift` is high risk because it combines note editing, sticky actions, copy feedback, delete confirmation, and scroll behavior.
- `AudioRecordingService.swift` is risky because it touches microphone permissions, AVAudioEngine, AVAudioRecorder, metering, and silence detection.
- `WhisperModelManager.swift` is risky because it combines downloads, progress observation, file storage, active model selection, and `UserDefaults`.
- `WhisperTranscriptionService.swift` is risky because it shells out to local `whisper-cli` and parses process output.

## Bugs To Guard Against

- A recording started from a note must not create a new note when stopped from the global bottom button.
- Smart stop must not lose the original recording target.
- Reload must not reset selected model to a default if the selected model is still downloaded.
- Empty model state must not expose active recording controls.
- Copy must copy the full note text, including appended transcript blocks.
- The last note must not be clipped by bottom controls.
- The notes list should open near the newest note.

## Undefined Policy

If a note-targeted recording finishes after the original target note has been deleted, the fallback behavior is not yet explicitly defined. Do not silently choose a behavior during refactor; define the product policy first.

