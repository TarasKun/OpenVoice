import AVFoundation
import Foundation
import Observation

enum AudioRecordingError: LocalizedError {
    case microphoneAccessDenied
    case missingInputNode
    case unableToCreateRecordingDirectory

    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            "Microphone access was denied."
        case .missingInputNode:
            "No microphone input node is available."
        case .unableToCreateRecordingDirectory:
            "Unable to create the recordings directory."
        }
    }
}

@MainActor
@Observable
final class AudioRecordingService {
    private let audioEngine = AVAudioEngine()
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var silenceStartedAt: Date?
    private var onAutoStop: ((URL) -> Void)?

    var isRecording = false
    var currentDecibels: Float = -120
    var noiseThresholdDecibels: Float = -42
    var requiredSilenceDuration: TimeInterval = 7
    var lastErrorMessage: String?

    func requestMicrophoneAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    func startRecording(onAutoStop: @escaping (URL) -> Void) async {
        guard !isRecording else { return }

        let hasAccess = await requestMicrophoneAccess()
        guard hasAccess else {
            lastErrorMessage = AudioRecordingError.microphoneAccessDenied.localizedDescription
            return
        }

        do {
            let url = try makeRecordingURL()
            try configureRecorder(url: url)
            try configureAudioEngine()

            self.onAutoStop = onAutoStop
            recordingURL = url
            silenceStartedAt = nil
            currentDecibels = -120

            recorder?.record()
            try audioEngine.start()
            isRecording = true
            lastErrorMessage = nil
        } catch {
            cleanupAfterStop()
            lastErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func stopRecording() -> URL? {
        guard isRecording else { return recordingURL }

        recorder?.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        let finishedURL = recordingURL
        cleanupAfterStop()
        return finishedURL
    }

    private func configureRecorder(url: URL) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        self.recorder = recorder
    }

    private func configureAudioEngine() throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.channelCount > 0 else {
            throw AudioRecordingError.missingInputNode
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let decibels = Self.calculateDecibels(from: buffer)

            Task { @MainActor in
                self.handleMeterUpdate(decibels)
            }
        }
    }

    private func handleMeterUpdate(_ decibels: Float) {
        guard isRecording else { return }

        currentDecibels = decibels

        if decibels < noiseThresholdDecibels {
            if silenceStartedAt == nil {
                silenceStartedAt = .now
            }

            if let silenceStartedAt, Date.now.timeIntervalSince(silenceStartedAt) > requiredSilenceDuration {
                let callback = onAutoStop
                if let url = stopRecording() {
                    callback?(url)
                }
            }
        } else {
            silenceStartedAt = nil
        }
    }

    private static func calculateDecibels(from buffer: AVAudioPCMBuffer) -> Float {
        guard
            let channelData = buffer.floatChannelData,
            buffer.frameLength > 0
        else {
            return -120
        }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        var totalMeanSquare: Float = 0

        for channel in 0..<channelCount {
            let samples = channelData[channel]
            var channelMeanSquare: Float = 0

            for frame in 0..<frameLength {
                let sample = samples[frame]
                channelMeanSquare += sample * sample
            }

            totalMeanSquare += channelMeanSquare / Float(frameLength)
        }

        let meanSquare = max(totalMeanSquare / Float(channelCount), Float.leastNonzeroMagnitude)
        return 10 * log10(meanSquare)
    }

    private func makeRecordingURL() throws -> URL {
        let supportDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = supportDirectory.appending(path: "OpenVoice/Recordings", directoryHint: .isDirectory)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw AudioRecordingError.unableToCreateRecordingDirectory
        }

        return directory.appending(path: "\(UUID().uuidString).wav")
    }

    private func cleanupAfterStop() {
        isRecording = false
        recorder = nil
        recordingURL = nil
        silenceStartedAt = nil
        onAutoStop = nil
    }
}
