@preconcurrency import AVFoundation
import Foundation
@preconcurrency import Speech

/// Live transcription for a recording in progress, through `SpeechAnalyzer`.
///
/// The recognized speech arrives as an ordered stream, so the caller can show
/// it and save it while the meeting continues. `SFSpeechRecognizer` stops after
/// about one minute of audio, which is why a long meeting needs this interface.
@available(macOS 26, *)
final class LiveSpeechAnalyzerSession: @unchecked Sendable {
    /// Every segment recognized so far, sent again whenever the text grows.
    let transcripts: AsyncStream<[SpeechRecognitionSegment]>

    private let analyzer: SpeechAnalyzer
    private let input: AsyncStream<AnalyzerInput>.Continuation
    private let transcriptContinuation: AsyncStream<[SpeechRecognitionSegment]>.Continuation
    private let converter: LiveAudioFormatConverter?
    private let lock = NSLock()
    private var results: Task<Void, Never>?
    private var isFinished = false

    static func start(localeIdentifier: String) async throws -> LiveSpeechAnalyzerSession {
        guard SpeechTranscriber.isAvailable else {
            throw SpeechTranscriptionError.unavailable
        }
        guard let locale = await SpeechTranscriber.supportedLocale(
            equivalentTo: Locale(identifier: localeIdentifier)
        ) else {
            throw SpeechTranscriptionError.unavailable
        }
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )
        // A model that needs installing must not hold up the recording. File
        // transcription installs it when the meeting ends.
        guard await AssetInventory.status(forModules: [transcriber]) == .installed else {
            throw SpeechTranscriptionError.modelUnavailable
        }
        let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        )
        return LiveSpeechAnalyzerSession(transcriber: transcriber, analyzerFormat: analyzerFormat)
    }

    private init(transcriber: SpeechTranscriber, analyzerFormat: AVAudioFormat?) {
        let (inputStream, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
        let (transcriptStream, transcriptContinuation) = AsyncStream<[SpeechRecognitionSegment]>
            .makeStream()
        input = inputContinuation
        transcripts = transcriptStream
        self.transcriptContinuation = transcriptContinuation
        converter = analyzerFormat.map(LiveAudioFormatConverter.init(target:))
        analyzer = SpeechAnalyzer(modules: [transcriber])

        results = Task { [analyzer, transcriptContinuation] in
            defer { transcriptContinuation.finish() }
            do {
                try await analyzer.start(inputSequence: inputStream)
            } catch {
                DiagnosticLogger.partialFailure(
                    operation: "live_transcribe_start",
                    error: error,
                    context: "fallback=file_transcription"
                )
                return
            }
            var recognized: [SpeechRecognitionSegment] = []
            do {
                for try await result in transcriber.results {
                    guard let segment = Self.segment(from: result) else { continue }
                    if result.isFinal {
                        recognized.append(segment)
                        transcriptContinuation.yield(recognized)
                    } else {
                        transcriptContinuation.yield(recognized + [segment])
                    }
                }
            } catch {
                DiagnosticLogger.partialFailure(
                    operation: "live_transcribe",
                    error: error,
                    context: "recognized=\(recognized.count)"
                )
            }
        }
    }

    /// Called from the audio tap thread for every captured buffer.
    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else { return }
        guard let converter else {
            input.yield(AnalyzerInput(buffer: buffer))
            return
        }
        guard let converted = converter.convert(buffer) else { return }
        input.yield(AnalyzerInput(buffer: converted))
    }

    func finish() async {
        guard markFinished() else { return }
        input.finish()
        try? await analyzer.finalizeAndFinishThroughEndOfInput()
        await results?.value
    }

    /// Marks the session finished. Returns false when it already was.
    private func markFinished() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else { return false }
        isFinished = true
        return true
    }

    func cancel() {
        _ = markFinished()
        input.finish()
        results?.cancel()
        results = nil
        transcriptContinuation.finish()
        let analyzer = analyzer
        Task { await analyzer.cancelAndFinishNow() }
    }

    private static func segment(
        from result: SpeechTranscriber.Result
    ) -> SpeechRecognitionSegment? {
        let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let start = result.range.start.seconds
        let duration = result.range.duration.seconds
        return SpeechRecognitionSegment(
            text: text,
            startTime: start.isFinite ? max(0, start) : 0,
            duration: duration.isFinite ? max(0, duration) : 0
        )
    }
}

/// Holds the one buffer a conversion pass may read. The conversion block runs on
/// the calling thread, so the lock only satisfies the concurrency checker.
private final class PendingBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: AVAudioPCMBuffer?

    init(_ buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }

    func take() -> AVAudioPCMBuffer? {
        lock.lock()
        defer { lock.unlock() }
        let pending = buffer
        buffer = nil
        return pending
    }
}

/// Converts captured microphone audio into the format the speech analyzer asked
/// for. It holds one converter, so it must be used from one thread at a time.
final class LiveAudioFormatConverter {
    private let target: AVAudioFormat
    private var converter: AVAudioConverter?

    init(target: AVAudioFormat) {
        self.target = target
    }

    func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard buffer.format != target else { return buffer }
        if converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: target)
        }
        guard let converter else { return nil }
        let ratio = target.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 1_024
        guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else {
            return nil
        }
        let source = PendingBuffer(buffer)
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            guard let next = source.take() else {
                inputStatus.pointee = .noDataNow
                return nil
            }
            inputStatus.pointee = .haveData
            return next
        }
        guard status != .error, output.frameLength > 0 else { return nil }
        return output
    }
}
