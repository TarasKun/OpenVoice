# Open Voice

Open Voice is a macOS 14+ menu bar utility for local voice transcription.

## Current MVP Slice

- Swift 5.10 package scaffold for the macOS app code.
- SwiftUI `MenuBarExtra` entry point.
- SwiftData `TranscriptionItem` model and app container.
- `AVAudioRecorder` WAV capture configured for 16 kHz mono PCM.
- `AVAudioEngine` input tap for live decibel metering.
- Smart stop after more than 7 consecutive seconds below the noise threshold.
- Whisper model selection, local model storage, download/delete controls, and streamed download progress.
- Clipboard copy path after transcription completion.
- `whisper.cpp` bridge boundary stubbed in `WhisperTranscriptionService`.

## Bundle Configuration

Use `Config/Info.plist` for the app target so the finished bundle runs as a menu bar agent:

- `LSUIElement = YES`
- `NSMicrophoneUsageDescription`
- minimum macOS `14.0`

Use `Config/OpenVoice.entitlements` when App Sandbox is enabled. It includes microphone input and network client access for model downloads.

## Build Note

This code uses SwiftData macros. The active developer tools must include the macOS 14 SDK and `SwiftDataMacros`; full Xcode 15+ is recommended. The local Command Line Tools install in this workspace currently cannot load `SwiftDataMacros`, so `swift build` cannot complete here until the developer directory is switched to a compatible Xcode installation.
