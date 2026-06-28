import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \TranscriptionItem.timestamp, order: .forward)
    private var items: [TranscriptionItem]
    let continuationItemID: UUID?
    let isRecording: Bool
    let isTranscribing: Bool
    let onRecordInto: (TranscriptionItem) -> Void

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView("No transcriptions yet", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(items) { item in
                            TranscriptionRowView(
                                item: item,
                                isContinuationTarget: continuationItemID == item.id,
                                isRecording: isRecording,
                                isTranscribing: isTranscribing,
                                onRecordInto: onRecordInto
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct TranscriptionRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TranscriptionItem
    let isContinuationTarget: Bool
    let isRecording: Bool
    let isTranscribing: Bool
    let onRecordInto: (TranscriptionItem) -> Void
    @State private var isConfirmingDelete = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Transcript", text: $item.text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .lineLimit(1...40)
                    .onChange(of: item.text) { _, _ in
                        save()
                    }
            }

            VStack(spacing: 10) {
                actionButton(systemImage: "xmark", help: "Delete note") {
                    isConfirmingDelete = true
                }

                actionButton(systemImage: recordIconName, help: "Record into this note") {
                    onRecordInto(item)
                }
                .disabled(isTranscribing)

                actionButton(systemImage: "doc.on.doc", help: "Copy transcript") {
                    ClipboardService.copy(item.text)
                }
            }
            .frame(width: 24)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isContinuationTarget ? Color.accentColor : Color.clear, lineWidth: 2)
        }
        .overlay(alignment: .bottomTrailing) {
            if isConfirmingDelete {
                deleteConfirmationView
                    .padding(8)
            }
        }
    }

    private var recordIconName: String {
        if isContinuationTarget, isRecording {
            "stop.circle.fill"
        } else {
            "record.circle"
        }
    }

    private var deleteConfirmationView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("Are you sure you want to delete this note?")
                .font(.caption)
                .multilineTextAlignment(.trailing)

            HStack(spacing: 8) {
                Button("Cancel") {
                    isConfirmingDelete = false
                }

                Button("Delete", role: .destructive) {
                    delete()
                }
            }
            .controlSize(.small)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 8, y: 3)
    }

    private func actionButton(systemImage: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save edited transcription: \(error)")
        }
    }

    private func delete() {
        modelContext.delete(item)
        save()
    }
}
