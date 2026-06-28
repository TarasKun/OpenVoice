import SwiftData
import SwiftUI

@MainActor
struct MainMenuView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var audioService: AudioRecordingService
    @State private var modelManager: WhisperModelManager
    @State private var transcriber = WhisperTranscriptionService()
    @State private var isTranscribing = false
    @State private var statusMessage: String?

    init() {
        _audioService = State(initialValue: AudioRecordingService())
        _modelManager = State(initialValue: WhisperModelManager())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RecordingControlView(
                isRecording: audioService.isRecording,
                isTranscribing: isTranscribing,
                currentDecibels: audioService.currentDecibels,
                thresholdDecibels: audioService.noiseThresholdDecibels,
                action: toggleRecording
            )

            if let statusMessage {
                Text(statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ModelManagerView(modelManager: modelManager)

            Divider()

            HistoryView()
        }
        .padding(16)
        .frame(width: 380, height: 560, alignment: .top)
    }

    private func toggleRecording() {
        if audioService.isRecording {
            guard let url = audioService.stopRecording() else { return }
            Task { await transcribe(url) }
        } else {
            Task {
                await audioService.startRecording { url in
                    Task { await transcribe(url) }
                }
            }
        }
    }

    private func transcribe(_ audioURL: URL) async {
        isTranscribing = true
        statusMessage = "Transcribing..."

        do {
            let modelURL = modelManager.localURL(for: modelManager.selectedModel)
            let text = try await transcriber.transcribe(audioURL: audioURL, modelURL: modelURL)
            let item = TranscriptionItem(text: text)

            modelContext.insert(item)
            try modelContext.save()
            ClipboardService.copy(text)
            statusMessage = "Copied transcription to clipboard."
        } catch {
            statusMessage = error.localizedDescription
        }

        isTranscribing = false
    }
}
