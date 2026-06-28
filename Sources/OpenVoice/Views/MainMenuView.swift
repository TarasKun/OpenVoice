import AppKit
import SwiftData
import SwiftUI

private enum RecordingTarget: Equatable {
    case newNote
    case existingNote(UUID)

    var existingNoteID: UUID? {
        if case .existingNote(let id) = self {
            id
        } else {
            nil
        }
    }
}

@MainActor
struct MainMenuView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var audioService: AudioRecordingService
    @State private var modelManager: WhisperModelManager
    @State private var transcriber = WhisperTranscriptionService()
    @State private var isTranscribing = false
    @State private var isShowingSettings = false
    @State private var recordingTarget: RecordingTarget?
    @State private var statusMessage: String?
    @State private var reloadID = UUID()

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
                recordingTargetItemID: recordingTarget?.existingNoteID,
                isRecording: audioService.isRecording,
                isTranscribing: isTranscribing,
                canRecord: modelManager.activeModel != nil,
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

                if modelManager.activeModel == nil {
                    Text("No models available. Go to Settings to download a model.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    RecordingControlView(
                        isRecording: audioService.isRecording,
                        isTranscribing: isTranscribing,
                        currentDecibels: audioService.currentDecibels,
                        action: toggleRecording
                    )
                }
            }
        }
        .id(reloadID)
        .padding(16)
        .frame(width: 380, height: 560, alignment: .top)
        .contextMenu {
            Button {
                reloadWidget()
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }

            Divider()

            Button {
                quitApplication()
            } label: {
                Label("Quit", systemImage: "power")
            }
        }
    }

    private func toggleRecording() {
        guard modelManager.activeModel != nil else { return }

        if audioService.isRecording {
            guard let url = audioService.stopRecording() else { return }
            Task { await transcribe(url) }
        } else {
            recordingTarget = .newNote
            Task {
                await audioService.startRecording { url in
                    Task { await transcribe(url) }
                }
            }
        }
    }

    private func recordInto(_ item: TranscriptionItem) {
        guard !isTranscribing, modelManager.activeModel != nil else { return }

        if audioService.isRecording {
            guard recordingTarget == .existingNote(item.id) else { return }
            guard let url = audioService.stopRecording() else { return }
            Task { await transcribe(url) }
        } else {
            recordingTarget = .existingNote(item.id)
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
            guard let activeModel = modelManager.activeModel else {
                statusMessage = "No models available. Go to Settings to download a model."
                recordingTarget = nil
                isTranscribing = false
                return
            }

            let modelURL = modelManager.localURL(for: activeModel)
            let text = try await transcriber.transcribe(audioURL: audioURL, modelURL: modelURL)

            if let noteID = recordingTarget?.existingNoteID, let item = try fetchItem(id: noteID) {
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

        recordingTarget = nil
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

    private func reloadWidget() {
        if audioService.isRecording {
            _ = audioService.stopRecording()
        }

        audioService = AudioRecordingService()
        modelManager = WhisperModelManager()
        transcriber = WhisperTranscriptionService()
        isTranscribing = false
        isShowingSettings = false
        recordingTarget = nil
        statusMessage = nil
        reloadID = UUID()
    }

    private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
}
