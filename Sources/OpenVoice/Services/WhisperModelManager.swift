import Foundation
import Observation

@MainActor
@Observable
final class WhisperModelManager {
    var selectedModel: WhisperModelSize = .base
    var downloadProgress: [WhisperModelSize: Double] = [:]
    var downloadedModels: Set<WhisperModelSize> = []
    var lastErrorMessage: String?

    private var downloadTasks: [WhisperModelSize: Task<Void, Never>] = [:]

    init() {
        refreshDownloadedModels()
    }

    func localURL(for model: WhisperModelSize) -> URL {
        modelsDirectory.appending(path: model.fileName)
    }

    func isDownloaded(_ model: WhisperModelSize) -> Bool {
        downloadedModels.contains(model)
    }

    func refreshDownloadedModels() {
        downloadedModels = Set(
            WhisperModelSize.allCases.filter { FileManager.default.fileExists(atPath: localURL(for: $0).path) }
        )
    }

    func download(_ model: WhisperModelSize) {
        guard downloadTasks[model] == nil else { return }

        downloadProgress[model] = 0
        let task = Task { [weak self] in
            guard let self else { return }

            do {
                try FileManager.default.createDirectory(at: self.modelsDirectory, withIntermediateDirectories: true)
                let destinationURL = self.localURL(for: model)
                let temporaryURL = self.modelsDirectory.appending(path: "\(model.fileName).download")

                if FileManager.default.fileExists(atPath: temporaryURL.path) {
                    try FileManager.default.removeItem(at: temporaryURL)
                }

                let (bytes, response) = try await URLSession.shared.bytes(from: model.downloadURL)
                let expectedLength = Double(response.expectedContentLength)
                FileManager.default.createFile(atPath: temporaryURL.path, contents: nil)

                let fileHandle = try FileHandle(forWritingTo: temporaryURL)
                var receivedLength = 0

                for try await byte in bytes {
                    try Task.checkCancellation()
                    try fileHandle.write(contentsOf: [byte])
                    receivedLength += 1

                    if expectedLength > 0 {
                        self.downloadProgress[model] = min(Double(receivedLength) / expectedLength, 0.99)
                    }
                }

                try fileHandle.close()

                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)

                self.downloadProgress[model] = 1
                self.refreshDownloadedModels()
                self.lastErrorMessage = nil
            } catch {
                self.lastErrorMessage = error.localizedDescription
            }

            self.downloadTasks[model] = nil
        }

        downloadTasks[model] = task
    }

    func delete(_ model: WhisperModelSize) {
        do {
            let url = localURL(for: model)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            downloadProgress[model] = nil
            refreshDownloadedModels()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private var modelsDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "OpenVoice/Models", directoryHint: .isDirectory)
    }
}
