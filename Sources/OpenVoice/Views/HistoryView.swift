import AppKit
import SwiftData
import SwiftUI

struct HistoryView: View {
    private let bottomAnchorID = "history-bottom-anchor"

    @Query(sort: \TranscriptionItem.timestamp, order: .forward)
    private var items: [TranscriptionItem]
    let recordingTargetItemID: UUID?
    let isRecording: Bool
    let isTranscribing: Bool
    let canRecord: Bool
    let onRecordInto: (TranscriptionItem) -> Void

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView("No transcriptions yet", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(items) { item in
                                TranscriptionRowView(
                                    item: item,
                                    isRecordingTarget: recordingTargetItemID == item.id,
                                    isRecording: isRecording,
                                    isTranscribing: isTranscribing,
                                    canRecord: canRecord,
                                    onRecordInto: onRecordInto,
                                    onTextExpanded: {
                                        DispatchQueue.main.async {
                                            scrollProxy.scrollTo(item.id, anchor: .bottom)
                                        }
                                    }
                                )
                                .id(item.id)
                            }

                            Color.clear
                                .frame(height: 1)
                                .id(bottomAnchorID)
                        }
                        .padding(.vertical, 2)
                        .padding(.bottom, 14)
                    }
                    .coordinateSpace(name: "historyScroll")
                    .onAppear {
                        scrollToNewest(using: scrollProxy)
                    }
                    .onChange(of: items.count) { _, _ in
                        scrollToNewest(using: scrollProxy)
                    }
                }
            }
        }
    }

    private func scrollToNewest(using scrollProxy: ScrollViewProxy) {
        guard !items.isEmpty else { return }

        for delay in [0.0, 0.08, 0.18, 0.35] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                scrollProxy.scrollTo(bottomAnchorID, anchor: .bottom)
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
    let canRecord: Bool
    let onRecordInto: (TranscriptionItem) -> Void
    let onTextExpanded: () -> Void
    @State private var isConfirmingDelete = false
    @State private var textHeight: CGFloat = 24
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)

            ExpandingNoteTextView(
                text: $item.text,
                calculatedHeight: $textHeight,
                onTextChanged: {
                    save()
                }
            )
            .frame(height: textHeight)
            .onChange(of: textHeight) { oldHeight, newHeight in
                if newHeight > oldHeight + 0.5 {
                    onTextExpanded()
                }
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
                .disabled(isTranscribing || !canRecord)

                actionButton(systemImage: didCopy ? "checkmark" : "doc.on.doc", help: didCopy ? "Copied" : "Copy transcript") {
                    copyFullNote()
                }
                .foregroundStyle(didCopy ? .green : .primary)
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
        withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
            didCopy = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeOut(duration: 0.2)) {
                didCopy = false
            }
        }
    }

    private func delete() {
        modelContext.delete(item)
        save()
    }
}

private struct ExpandingNoteTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    let onTextChanged: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.string = text
        return textView
    }

    func updateNSView(_ textView: NSTextView, context: Context) {
        context.coordinator.parent = self

        if textView.string != text {
            textView.string = text
        }

        textView.font = .preferredFont(forTextStyle: .body)
        recalculateHeight(for: textView)
    }

    private func recalculateHeight(for textView: NSTextView) {
        DispatchQueue.main.async {
            guard let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else { return }

            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let nextHeight = max(24, ceil(usedRect.height + textView.textContainerInset.height * 2))

            if abs(calculatedHeight - nextHeight) > 0.5 {
                calculatedHeight = nextHeight
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ExpandingNoteTextView

        init(parent: ExpandingNoteTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            parent.recalculateHeight(for: textView)
            parent.onTextChanged()
        }
    }
}
