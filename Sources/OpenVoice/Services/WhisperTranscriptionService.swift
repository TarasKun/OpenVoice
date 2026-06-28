import Foundation

enum WhisperTranscriptionError: LocalizedError {
    case missingModel
    case executableMissing
    case commandFailed(String)
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .missingModel:
            "The selected Whisper model has not been downloaded."
        case .executableMissing:
            "whisper-cli was not found. Install whisper.cpp or add whisper-cli to /opt/homebrew/bin or /usr/local/bin."
        case .commandFailed(let message):
            "Whisper transcription failed: \(message)"
        case .emptyResult:
            "Whisper finished, but did not return any transcription text."
        }
    }
}

struct WhisperTranscriptionService {
    func transcribe(audioURL: URL, modelURL: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw WhisperTranscriptionError.missingModel
        }

        let executableURL = try findWhisperCLI()
        let output = try await runWhisperCLI(
            executableURL: executableURL,
            audioURL: audioURL,
            modelURL: modelURL
        )
        let text = clean(output)

        guard !text.isEmpty else {
            throw WhisperTranscriptionError.emptyResult
        }

        return text
    }

    private func findWhisperCLI() throws -> URL {
        let candidates = [
            "/opt/homebrew/bin/whisper-cli",
            "/usr/local/bin/whisper-cli",
            "/usr/bin/whisper-cli"
        ]

        if let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return URL(filePath: path)
        }

        throw WhisperTranscriptionError.executableMissing
    }

    private func runWhisperCLI(executableURL: URL, audioURL: URL, modelURL: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = executableURL
            process.arguments = [
                "--model", modelURL.path,
                "--file", audioURL.path,
                "--language", "auto",
                "--no-timestamps",
                "--no-prints"
            ]
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let message = clean(errorOutput.isEmpty ? output : errorOutput)
                    continuation.resume(throwing: WhisperTranscriptionError.commandFailed(message))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func clean(_ output: String) -> String {
        output
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
