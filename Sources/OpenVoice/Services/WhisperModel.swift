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

    var diskSize: String {
        switch self {
        case .tiny:
            "74 MB"
        case .base:
            "142 MB"
        case .small:
            "466 MB"
        case .medium:
            "1.5 GB"
        }
    }

    var estimatedVRAMUsage: String {
        switch self {
        case .tiny:
            "~390 MB"
        case .base:
            "~500 MB"
        case .small:
            "~1 GB"
        case .medium:
            "~2.6 GB"
        }
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }
}
