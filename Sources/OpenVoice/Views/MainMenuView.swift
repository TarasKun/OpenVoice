import SwiftData
import SwiftUI

@MainActor
struct MainMenuView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var audioService: AudioRecordingService
    @State private var modelManager: WhisperModelManager
    @State private var transcriber = WhisperTranscriptionService()
    @State private var isTranscribing = false
    @State private var isShowingSettings = false
    @State private var continuationItemID: UUID?
    @State private var statusMessage: String?

    init() {
        _audioService = State(initialValue: AudioRecordingService())
        _modelManager = State(initialValue: WhisperModelManager())
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Open Voice")
                    .font(.headline)

                Spacer()

                Button {
                    isShowingSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Settings")
                .popover(isPresented: $isShowingSettings, arrowEdge: .top) {
                    ModelManagerView(modelManager: modelManager)
                        .padding(16)
                        .frame(width: 340)
                }
            }

            HistoryView(
                continuationItemID: continuationItemID,
                isRecording: audioService.isRecording,
                isTranscribing: isTranscribing,
                onRecordInto: recordInto
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 8) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                RecordingControlView(
                    isRecording: audioService.isRecording,
                    isTranscribing: isTranscribing,
                    currentDecibels: audioService.currentDecibels,
                    action: toggleRecording
                )
            }
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

    private func recordInto(_ item: TranscriptionItem) {
        guard !isTranscribing else { return }

        continuationItemID = item.id

        if audioService.isRecording {
            guard let url = audioService.stopRecording() else { return }
            Task { await transcribe(url) }
        } else {
            statusMessage = "Recording will append to this note."
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

            if let continuationItemID, let item = try fetchItem(id: continuationItemID) {
                item.text = appendedText(existingText: item.text, newText: text)
                statusMessage = "Appended transcription and copied it to clipboard."
            } else {
                let item = TranscriptionItem(text: text)
                modelContext.insert(item)
                statusMessage = "Copied transcription to clipboard."
            }

            try modelContext.save()
            ClipboardService.copy(text)
        } catch {
            statusMessage = error.localizedDescription
        }

        isTranscribing = false
    }

    private func fetchItem(id: UUID) throws -> TranscriptionItem? {
        let descriptor = FetchDescriptor<TranscriptionItem>(
            predicate: #Predicate { item in
                item.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func appendedText(existingText: String, newText: String) -> String {
        let trimmedExistingText = existingText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewText = newText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedExistingText.isEmpty else {
            return trimmedNewText
        }

        guard !trimmedNewText.isEmpty else {
            return trimmedExistingText
        }

        return "\(trimmedExistingText)\n\n\(trimmedNewText)"
    }
}
