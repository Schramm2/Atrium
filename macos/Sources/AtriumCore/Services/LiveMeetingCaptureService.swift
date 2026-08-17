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
    speechRequest: SFSpeechAudioBufferRecognitionRequest?,
    liveSpeech: (@Sendable (AVAudioPCMBuffer) -> Void)?
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
            liveSpeech?(buffer)
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

/// Carries captured audio to live transcription. It accepts buffers from the
/// audio tap before the speech session exists and discards them until it does,
/// so capture never waits for the speech model.
private final class LiveSpeechSink: @unchecked Sendable {
    private let lock = NSLock()
    private var receive: (@Sendable (AVAudioPCMBuffer) -> Void)?

    func attach(_ receive: @escaping @Sendable (AVAudioPCMBuffer) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        self.receive = receive
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let receive = receive
        lock.unlock()
        receive?(buffer)
    }
}

@MainActor
public final class LiveMeetingCaptureService: NSObject {
    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var liveSpeechSession: AnyObject?
    private var liveTranscriptTask: Task<Void, Never>?
    private let captureState = RealtimeCaptureState()
    private var hasInstalledTap = false

    public func requestPermission() async -> Bool {
        await MicrophoneAuthorization.request()
    }

    public func start(
        at url: URL,
        localeIdentifier: String = Locale.current.identifier,
        inputDeviceID: String = "",
        onPartialTranscript: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws {
        guard outputURL == nil, !hasInstalledTap else {
            throw AudioRecordingError.alreadyRecording
        }
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
        let liveSpeech = LiveSpeechSink()
        if #available(macOS 26, *), SpeechTranscriber.isAvailable {
            // The session is attached after capture starts, further down.
        } else if SFSpeechRecognizer.authorizationStatus() == .authorized,
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
                speechRequest: speechRequest,
                liveSpeech: { buffer in liveSpeech.append(buffer) }
            )
        )
        hasInstalledTap = true
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            cleanUp(removeOutputFile: true)
            throw error
        }

        // Capture is running, so preparing the speech model costs no audio.
        if #available(macOS 26, *), SpeechTranscriber.isAvailable {
            do {
                let session = try await LiveSpeechAnalyzerSession.start(
                    localeIdentifier: localeIdentifier
                )
                guard hasInstalledTap else {
                    session.cancel()
                    return
                }
                liveSpeechSession = session
                liveSpeech.attach { [weak session] buffer in session?.append(buffer) }
                liveTranscriptTask = Task { @MainActor [transcripts = session.transcripts] in
                    for await recognized in transcripts {
                        onPartialTranscript(recognized)
                    }
                }
            } catch {
                // The recording is the evidence that matters. Keep capturing
                // audio and let the transcript come from the saved file.
                DiagnosticLogger.partialFailure(
                    operation: "live_transcribe_start",
                    error: error,
                    context: "fallback=file_transcription"
                )
            }
        }
    }

    public func pause() {
        captureState.setAcceptsAudio(false)
    }

    public func resume() {
        captureState.setAcceptsAudio(true)
    }

    public func stop() async throws -> URL {
        guard let outputURL else { throw AudioRecordingError.noActiveRecording }
        releaseAudioEngine()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        await finishLiveSpeech()
        audioFile = nil
        self.outputURL = nil
        captureState.setAcceptsAudio(true)
        return outputURL
    }

    /// Lets the live transcript finish its last words before the caller reads it.
    private func finishLiveSpeech() async {
        guard let session = liveSpeechSession else { return }
        liveSpeechSession = nil
        if #available(macOS 26, *), let session = session as? LiveSpeechAnalyzerSession {
            await session.finish()
        }
        await liveTranscriptTask?.value
        liveTranscriptTask = nil
    }

    private func cancelLiveSpeech() {
        let session = liveSpeechSession
        liveSpeechSession = nil
        liveTranscriptTask?.cancel()
        liveTranscriptTask = nil
        if #available(macOS 26, *), let session = session as? LiveSpeechAnalyzerSession {
            session.cancel()
        }
    }

    public func cancel() {
        cleanUp(removeOutputFile: true)
    }

    /// Releases the microphone and the live transcript but keeps the recording,
    /// so a failure after capture never removes the audio.
    public func release() {
        cleanUp(removeOutputFile: false)
    }

    public var currentTime: TimeInterval {
        captureState.snapshot().currentTime
    }

    public var averagePower: Float { captureState.snapshot().averagePower }

    var audioEngineIdentity: ObjectIdentifier { ObjectIdentifier(audioEngine) }

    private func removeTapIfNeeded() {
        guard hasInstalledTap else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        hasInstalledTap = false
    }

    private func cleanUp(removeOutputFile: Bool) {
        releaseAudioEngine()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        cancelLiveSpeech()
        audioFile = nil
        if removeOutputFile, let outputURL {
            try? FileManager.default.removeItem(at: outputURL)
        }
        outputURL = nil
        captureState.setAcceptsAudio(true)
    }

    private func releaseAudioEngine() {
        removeTapIfNeeded()
        audioEngine.stop()
        audioEngine.reset()
        // Release the input audio unit as well as its tap. Keeping the same
        // engine alive can leave Bluetooth devices in their microphone route.
        audioEngine = AVAudioEngine()
    }
}
