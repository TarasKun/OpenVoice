import SwiftUI

struct ModelManagerView: View {
    @Bindable var modelManager: WhisperModelManager
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Models")
                    .font(.headline)

                Spacer()

                Button(action: onQuit) {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .padding(4)
                .contentShape(Rectangle())
                .help("Quit Open Voice")
            }

            Text(activeModelSummary)
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(WhisperModelSize.allCases) { model in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.displayName)
                            .font(.body)
                        Text(model.fileName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Size: \(model.diskSize) · RAM/VRAM: \(model.estimatedVRAMUsage)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if modelManager.downloadingModels.contains(model) {
                        if let progress = modelManager.downloadProgress[model] {
                            ProgressView(value: progress)
                                .frame(width: 56)
                        } else {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 56)
                        }
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
                .padding(8)
                .contentShape(Rectangle())
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(modelManager.activeModel == model ? Color.accentColor : Color.clear, lineWidth: 2)
                }
                .opacity(modelManager.isDownloaded(model) ? 1 : 0.72)
                .onTapGesture {
                    modelManager.select(model)
                }
            }

            if let lastErrorMessage = modelManager.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var activeModelSummary: String {
        if let activeModel = modelManager.activeModel {
            "Active model: Size \(activeModel.diskSize), RAM/VRAM \(activeModel.estimatedVRAMUsage)."
        } else {
            "No models downloaded."
        }
    }
}
