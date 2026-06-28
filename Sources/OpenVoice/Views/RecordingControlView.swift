import SwiftUI

struct RecordingControlView: View {
    let isRecording: Bool
    let isTranscribing: Bool
    let currentDecibels: Float
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "waveform")
                ProgressView(value: normalizedLevel)
                    .progressViewStyle(.linear)
                Text("\(Int(currentDecibels)) dB")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 54, alignment: .trailing)
            }
            .opacity(isRecording ? 1 : 0.16)
            .frame(height: 16)

            Button(action: action) {
                Label(buttonTitle, systemImage: buttonSystemImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isTranscribing)
        }
    }

    private var buttonTitle: String {
        if isTranscribing {
            "Transcribing"
        } else if isRecording {
            "Stop Recording"
        } else {
            "Start Recording"
        }
    }

    private var buttonSystemImage: String {
        if isRecording {
            "stop.circle.fill"
        } else {
            "record.circle"
        }
    }

    private var normalizedLevel: Double {
        let clamped = min(max(currentDecibels, -80), 0)
        return Double((clamped + 80) / 80)
    }
}
