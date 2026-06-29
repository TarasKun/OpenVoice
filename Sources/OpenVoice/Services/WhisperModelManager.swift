import Foundation
import Observation

@MainActor
@Observable
final class WhisperModelManager {
    private static let selectedModelDefaultsKey = "selectedWhisperModel"

    var selectedModel: WhisperModelSize?
    var downloadProgress: [WhisperModelSize: Double] = [:]
    var downloadingModels: Set<WhisperModelSize> = []
    var downloadedModels: Set<WhisperModelSize> = []
    var lastErrorMessage: String?

    var activeModel: WhisperModelSize? {
        if let selectedModel, downloadedModels.contains(selectedModel) {
            selectedModel
        } else {
            firstDownloadedModel
        }
    }

    private var downloadTasks: [WhisperModelSize: Task<Void, Never>] = [:]

    init() {
        selectedModel = Self.restoreSelectedModel()
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
        normalizeSelection()
    }

    func select(_ model: WhisperModelSize) {
        guard downloadedModels.contains(model) else { return }
        selectedModel = model
        persistSelection()
    }

    func download(_ model: WhisperModelSize) {
        guard downloadTasks[model] == nil else { return }

        downloadingModels.insert(model)
        downloadProgress[model] = nil
        let task = Task { [weak self] in
            guard let self else { return }

            do {
                try FileManager.default.createDirectory(at: self.modelsDirectory, withIntermediateDirectories: true)
                let destinationURL = self.localURL(for: model)

                let (temporaryURL, response) = try await Self.downloadFile(from: model.downloadURL) { [weak self] progress in
                    Task { @MainActor in
                        guard let self, self.downloadTasks[model] != nil else { return }
                        if let progress {
                            self.downloadProgress[model] = min(max(progress, 0), 0.99)
                        } else {
                            self.downloadProgress[model] = nil
                        }
                    }
                }

                if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
                    throw URLError(.badServerResponse)
                }

                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }

                try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)

                self.downloadProgress[model] = 1
                self.refreshDownloadedModels()
                self.select(model)
                self.lastErrorMessage = nil
            } catch {
                self.downloadProgress[model] = nil
                self.lastErrorMessage = error.localizedDescription
            }

            self.downloadingModels.remove(model)
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
            downloadingModels.remove(model)
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

    private var firstDownloadedModel: WhisperModelSize? {
        preferredFallbackModels.first { downloadedModels.contains($0) }
    }

    private var preferredFallbackModels: [WhisperModelSize] {
        [.small, .base, .medium, .largeV3Turbo, .largeV3TurboQ5]
    }

    private func normalizeSelection() {
        if downloadedModels.isEmpty {
            selectedModel = nil
            UserDefaults.standard.removeObject(forKey: Self.selectedModelDefaultsKey)
        } else if let selectedModel, downloadedModels.contains(selectedModel) {
            persistSelection()
        } else if let firstDownloadedModel {
            selectedModel = firstDownloadedModel
            persistSelection()
        }
    }

    private func persistSelection() {
        if let selectedModel {
            UserDefaults.standard.set(selectedModel.rawValue, forKey: Self.selectedModelDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.selectedModelDefaultsKey)
        }
    }

    private static func restoreSelectedModel() -> WhisperModelSize? {
        guard let rawValue = UserDefaults.standard.string(forKey: selectedModelDefaultsKey) else {
            return nil
        }

        return WhisperModelSize(rawValue: rawValue)
    }

    private static func downloadFile(
        from url: URL,
        onProgress: @escaping @Sendable (Double?) -> Void
    ) async throws -> (URL, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let observationBox = DownloadProgressObservationBox()
            let task = URLSession.shared.downloadTask(with: url) { temporaryURL, response, error in
                observationBox.observation?.invalidate()
                observationBox.observation = nil

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let temporaryURL, let response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                continuation.resume(returning: (temporaryURL, response))
            }

            observationBox.observation = task.progress.observe(\.fractionCompleted, options: [.initial, .new]) { progress, _ in
                if progress.totalUnitCount > 0 {
                    onProgress(progress.fractionCompleted)
                } else {
                    onProgress(nil)
                }
            }

            task.resume()
        }
    }
}

private final class DownloadProgressObservationBox: @unchecked Sendable {
    var observation: NSKeyValueObservation?
}
