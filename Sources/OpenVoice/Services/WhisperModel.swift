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

    var estimatedVRAMUsage: String {
        switch self {
        case .tiny:
            "~390 MB VRAM"
        case .base:
            "~500 MB VRAM"
        case .small:
            "~1 GB VRAM"
        case .medium:
            "~2.6 GB VRAM"
        }
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }
}
