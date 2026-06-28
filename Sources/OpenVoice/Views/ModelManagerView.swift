import SwiftUI

struct ModelManagerView: View {
    @Bindable var modelManager: WhisperModelManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Active model", selection: $modelManager.selectedModel) {
                ForEach(WhisperModelSize.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.menu)

            ForEach(WhisperModelSize.allCases) { model in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.displayName)
                            .font(.body)
                        Text(model.fileName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let progress = modelManager.downloadProgress[model], progress > 0, progress < 1 {
                        ProgressView(value: progress)
                            .frame(width: 56)
                    }

                    if modelManager.isDownloaded(model) {
                        Button {
                            modelManager.delete(model)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .help("Delete model")
                    } else {
                        Button {
                            modelManager.download(model)
                        } label: {
                            Image(systemName: "arrow.down.circle")
                        }
                        .help("Download model")
                    }
                }
            }

            if let lastErrorMessage = modelManager.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
