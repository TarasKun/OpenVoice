import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \TranscriptionItem.timestamp, order: .forward)
    private var items: [TranscriptionItem]
    let recordingTargetItemID: UUID?
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
                                isRecordingTarget: recordingTargetItemID == item.id,
                                isRecording: isRecording,
                                isTranscribing: isTranscribing,
                                onRecordInto: onRecordInto
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .coordinateSpace(name: "historyScroll")
            }
        }
    }
}

private struct TranscriptionRowView: View {
    private let notePadding: CGFloat = 14
    private let actionBlockHeight: CGFloat = 74
    private let confirmationBlockHeight: CGFloat = 86

    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TranscriptionItem
    let isRecordingTarget: Bool
    let isRecording: Bool
    let isTranscribing: Bool
    let onRecordInto: (TranscriptionItem) -> Void
    @State private var isConfirmingDelete = false

    var body: some View {
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
        .padding(notePadding)
        .padding(.trailing, 40)
        .frame(maxWidth: .infinity, minHeight: minimumNoteHeight, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isRecordingTarget ? Color.accentColor : Color.clear, lineWidth: 2)
        }
        .overlay(alignment: .topTrailing) {
            stickyActionOverlay
        }
    }

    private var stickyActionOverlay: some View {
        GeometryReader { proxy in
            actionBlock
                .padding(.top, notePadding)
                .padding(.trailing, notePadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(y: stickyYOffset(for: proxy.frame(in: .named("historyScroll"))))
        }
    }

    @ViewBuilder
    private var actionBlock: some View {
        if isConfirmingDelete {
            deleteConfirmationView
        } else {
            VStack(alignment: .leading, spacing: 8) {
                actionButton(systemImage: "xmark", help: "Delete note") {
                    isConfirmingDelete = true
                }

                actionButton(systemImage: recordIconName, help: "Record into this note") {
                    onRecordInto(item)
                }
                .disabled(isTranscribing)

                actionButton(systemImage: "doc.on.doc", help: "Copy transcript") {
                    copyFullNote()
                }
            }
            .frame(width: 24)
        }
    }

    private var minimumNoteHeight: CGFloat {
        actionBlockHeight + notePadding * 2
    }

    private var recordIconName: String {
        if isRecordingTarget, isRecording {
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

    private func stickyYOffset(for rowFrame: CGRect) -> CGFloat {
        let visibleActionBlockHeight = isConfirmingDelete ? confirmationBlockHeight : actionBlockHeight
        let topInset = notePadding
        let bottomInset = notePadding
        let pinnedOffset = max(0, -rowFrame.minY + topInset)
        let maxOffset = max(0, rowFrame.height - visibleActionBlockHeight - bottomInset)

        return min(pinnedOffset, maxOffset)
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

    private func copyFullNote() {
        ClipboardService.copy(item.text)
    }

    private func delete() {
        modelContext.delete(item)
        save()
    }
}
