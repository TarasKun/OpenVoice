import Foundation

enum WhisperModelSize: String, CaseIterable, Identifiable {
    case tiny
    case base
    case small
    case medium

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var fileName: String {
        "ggml-\(rawValue).bin"
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }
}
