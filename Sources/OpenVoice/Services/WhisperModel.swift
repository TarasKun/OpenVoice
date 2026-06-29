import Foundation

enum WhisperModelSize: String, CaseIterable, Identifiable {
    case base
    case small
    case medium
    case largeV3Turbo = "large-v3-turbo"
    case largeV3TurboQ5 = "large-v3-turbo-q5_0"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .base:
            "Base"
        case .small:
            "Small"
        case .medium:
            "Medium"
        case .largeV3Turbo:
            "Large v3 Turbo"
        case .largeV3TurboQ5:
            "Large v3 Turbo Q5"
        }
    }

    var fileName: String {
        "ggml-\(rawValue).bin"
    }

    var diskSize: String {
        switch self {
        case .base:
            "142 MB"
        case .small:
            "466 MB"
        case .medium:
            "1.5 GB"
        case .largeV3Turbo:
            "1.6 GB"
        case .largeV3TurboQ5:
            "547 MB"
        }
    }

    var estimatedVRAMUsage: String {
        switch self {
        case .base:
            "~500 MB"
        case .small:
            "~1 GB"
        case .medium:
            "~2.6 GB"
        case .largeV3Turbo:
            "~2.4 GB"
        case .largeV3TurboQ5:
            "~1.1 GB"
        }
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }
}
