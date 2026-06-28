import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \TranscriptionItem.timestamp, order: .reverse)
    private var items: [TranscriptionItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)

            if items.isEmpty {
                ContentUnavailableView("No transcriptions yet", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item.text)
                                    .font(.body)
                                    .textSelection(.enabled)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
    }
}
