# AI Context

OpenVoice is a native macOS menu bar app implemented as a Swift Package executable target. It uses SwiftUI `MenuBarExtra`, SwiftData for note history, AVFoundation for recording, and local `whisper-cli` for transcription.

## Current Architecture

- `Sources/OpenVoice/OpenVoiceApp.swift`: app entry, SwiftData container, menu bar scene.
- `Sources/OpenVoice/Views/MainMenuView.swift`: main orchestration. High-risk file because it owns recording target routing and transcription save behavior.
- `Sources/OpenVoice/Views/HistoryView.swift`: notes list, editable note rows, sticky actions, copy/delete/edit UI. Risky to modify without tests.
- `Sources/OpenVoice/Views/ModelManagerView.swift`: Settings model list UI.
- `Sources/OpenVoice/Views/RecordingControlView.swift`: bottom record/stop button and mic level display.
- `Sources/OpenVoice/Services/AudioRecordingService.swift`: AVAudioRecorder, AVAudioEngine metering, silence detection. Risky to modify without tests.
- `Sources/OpenVoice/Services/WhisperModelManager.swift`: downloaded model state, progress, selected model persistence. Risky to modify without tests.
- `Sources/OpenVoice/Services/WhisperTranscriptionService.swift`: invokes local `whisper-cli`. Risky to modify without tests.
- `Sources/OpenVoice/Models/TranscriptionItem.swift`: SwiftData note model.

There is currently no Swift Package test target.

## Critical Product Rules

1. Global recording creates a new note after transcription.
2. Note-targeted recording appends transcript to the original note.
3. If recording starts from a note and stops from the global bottom stop button, transcript must still append to the original note.
4. Note-targeted recording must not create a new note unless the original target note is unavailable and that fallback policy is explicitly defined.
5. Smart stop / silence detection must preserve the original recording target.
6. Selected Whisper model must persist across reload/app launch.
7. If no model is downloaded or active, record controls should not be available.

## State Locations

- Recording target and transcription save routing: `MainMenuView`.
- Recording state, current dB, silence timer, recording file URL: `AudioRecordingService`.
- Model selection, downloaded models, download progress, selected model persistence: `WhisperModelManager`.
- Notes: SwiftData `TranscriptionItem`.
- Per-row UI state: `HistoryView`.

## Read First

Future agents should read these files first:

1. `open_voice_spec.md`
2. `AI_CONTEXT.md`
3. `TESTING_PLAN.md`
4. `Sources/OpenVoice/Views/MainMenuView.swift`
5. `Sources/OpenVoice/Views/HistoryView.swift`

