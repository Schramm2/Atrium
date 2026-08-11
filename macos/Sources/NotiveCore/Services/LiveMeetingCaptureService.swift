@preconcurrency import AVFoundation
import Foundation
@preconcurrency import Speech

final class RealtimeCaptureState: @unchecked Sendable {
    struct Snapshot: Sendable {
        let currentTime: TimeInterval
        let averagePower: Float
    }

    private let lock = NSLock()
    private var acceptsAudio = true
    private var capturedFrames: AVAudioFramePosition = 0
    private var sampleRate: Double = 48_000
    private var power: Float = -80

    func reset(sampleRate: Double) {
        lock.lock()
        defer { lock.unlock() }
        acceptsAudio = true
        capturedFrames = 0
        self.sampleRate = sampleRate
        power = -80
    }

    func setAcceptsAudio(_ value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        acceptsAudio = value
    }

    func shouldAcceptAudio() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return acceptsAudio
    }

    func record(frameCount: AVAudioFrameCount, power: Float) {
        lock.lock()
        defer { lock.unlock() }
        capturedFrames += AVAudioFramePosition(frameCount)
        self.power = power
    }

    func recordWriteFailure() {
        lock.lock()
        defer { lock.unlock() }
        power = -80
    }

    func snapshot() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }
        return Snapshot(
            currentTime: sampleRate > 0 ? Double(capturedFrames) / sampleRate : 0,
            averagePower: power
        )
    }

    static func averagePower(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else { return -80 }
        let values = channels[0]
        var sum: Float = 0
        for index in 0..<Int(buffer.frameLength) {
            sum += values[index] * values[index]
        }
        let rms = sqrt(sum / Float(buffer.frameLength))
        return rms > 0 ? 20 * log10(rms) : -80
    }
}

private func makeAudioTapHandler(
    captureState: RealtimeCaptureState,
    audioFile: AVAudioFile,
    speechRequest: SFSpeechAudioBufferRecognitionRequest?
) -> AVAudioNodeTapBlock {
    { buffer, _ in
        guard captureState.shouldAcceptAudio() else { return }
        do {
            try audioFile.write(from: buffer)
            captureState.record(
                frameCount: buffer.frameLength,
                power: RealtimeCaptureState.averagePower(buffer)
            )
            speechRequest?.append(buffer)
        } catch {
            captureState.recordWriteFailure()
        }
    }
}

private func makeSpeechRecognitionHandler(
    onPartialTranscript: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
) -> (SFSpeechRecognitionResult?, (any Error)?) -> Void {
    { result, _ in
        guard let result else { return }
        let values: [SpeechRecognitionSegment] = result.bestTranscription.segments.map {
            SpeechRecognitionSegment(
                text: $0.substring,
                startTime: $0.timestamp,
                duration: $0.duration
            )
        }
        Task { @MainActor in onPartialTranscript(values) }
    }
}

@MainActor
public final class LiveMeetingCaptureService: NSObject, @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let captureState = RealtimeCaptureState()

    public func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        default:
            return false
        }
    }

    public func start(
        at url: URL,
        localeIdentifier: String = Locale.current.identifier,
        inputDeviceID: String = "",
        onPartialTranscript: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: url)

        let inputNode = audioEngine.inputNode
        try AudioDeviceService.selectInput(uniqueID: inputDeviceID, for: inputNode)
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AudioRecordingError.couldNotStart
        }
        let audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        self.audioFile = audioFile
        outputURL = url
        captureState.reset(sampleRate: format.sampleRate)

        var speechRequest: SFSpeechAudioBufferRecognitionRequest?
        if SFSpeechRecognizer.authorizationStatus() == .authorized,
           let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)),
           recognizer.isAvailable,
           recognizer.supportsOnDeviceRecognition {
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true
            request.addsPunctuation = true
            recognitionRequest = request
            speechRequest = request
            recognitionTask = recognizer.recognitionTask(
                with: request,
                resultHandler: makeSpeechRecognitionHandler(
                    onPartialTranscript: onPartialTranscript
                )
            )
        }

        let captureState = self.captureState
        inputNode.installTap(
            onBus: 0,
            bufferSize: 2_048,
            format: format,
            block: makeAudioTapHandler(
                captureState: captureState,
                audioFile: audioFile,
                speechRequest: speechRequest
            )
        )
        audioEngine.prepare()
        try audioEngine.start()
    }

    public func pause() {
        captureState.setAcceptsAudio(false)
    }

    public func resume() {
        captureState.setAcceptsAudio(true)
    }

    public func stop() throws -> URL {
        guard let outputURL else { throw AudioRecordingError.noActiveRecording }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioFile = nil
        self.outputURL = nil
        captureState.setAcceptsAudio(true)
        return outputURL
    }

    public func cancel() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioFile = nil
        if let outputURL { try? FileManager.default.removeItem(at: outputURL) }
        outputURL = nil
        captureState.setAcceptsAudio(true)
    }

    public var currentTime: TimeInterval {
        captureState.snapshot().currentTime
    }

    public var averagePower: Float { captureState.snapshot().averagePower }
}
