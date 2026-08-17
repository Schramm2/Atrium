@preconcurrency import AVFoundation
import CoreMedia
import Foundation
@preconcurrency import Speech

/// Transcribes a saved audio file of any length and reports the speech
/// recognized so far while it works.
@MainActor
protocol SpeechFileTranscribing: AnyObject {
    func transcribe(
        audioURL: URL,
        locale: Locale,
        onProgress: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment]

    func cancel()
}

// MARK: - Speech analyzer

/// Reads a whole recording through `SpeechAnalyzer`, which is the Apple
/// interface built for long-form audio. Results arrive while the file is read,
/// so a caller can save the transcript in parts.
@available(macOS 26, *)
@MainActor
final class SpeechAnalyzerFileTranscriber: SpeechFileTranscribing {
    private var work: Task<[SpeechRecognitionSegment], Error>?

    func transcribe(
        audioURL: URL,
        locale: Locale,
        onProgress: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment] {
        let (progress, continuation) = AsyncStream<[SpeechRecognitionSegment]>.makeStream()
        let work = Task.detached(priority: .userInitiated) {
            defer { continuation.finish() }
            return try await Self.analyze(audioURL: audioURL, locale: locale) { recognized in
                continuation.yield(recognized)
            }
        }
        self.work = work
        defer { self.work = nil }
        for await recognized in progress {
            onProgress(recognized)
        }
        return try await work.value
    }

    func cancel() {
        work?.cancel()
        work = nil
    }

    private static func analyze(
        audioURL: URL,
        locale: Locale,
        onProgress: @escaping @Sendable ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment] {
        guard SpeechTranscriber.isAvailable else {
            throw SpeechTranscriptionError.unavailable
        }
        guard let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            throw SpeechTranscriptionError.unavailable
        }
        let transcriber = SpeechTranscriber(
            locale: supported,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: [.audioTimeRange]
        )
        try await installModels(for: transcriber)
        try Task.checkCancellation()

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let collected = Task {
            var recognized: [SpeechRecognitionSegment] = []
            for try await result in transcriber.results where result.isFinal {
                guard let segment = Self.segment(from: result) else { continue }
                recognized.append(segment)
                onProgress(recognized)
            }
            return recognized
        }
        do {
            let file = try AVAudioFile(forReading: audioURL)
            try await withTaskCancellationHandler {
                try await analyzer.start(inputAudioFile: file, finishAfterFile: true)
            } onCancel: {
                Task { await analyzer.cancelAndFinishNow() }
            }
        } catch {
            collected.cancel()
            throw Self.transcriptionError(from: error)
        }
        do {
            return try await collected.value
        } catch {
            throw Self.transcriptionError(from: error)
        }
    }

    private static func installModels(for transcriber: SpeechTranscriber) async throws {
        do {
            guard let request = try await AssetInventory.assetInstallationRequest(
                supporting: [transcriber]
            ) else { return }
            try await request.downloadAndInstall()
        } catch {
            throw SpeechTranscriptionError.modelUnavailable
        }
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

    private static func transcriptionError(from error: Error) -> Error {
        if error is CancellationError || error is SpeechTranscriptionError { return error }
        return SpeechTranscriptionError.failed(error.localizedDescription)
    }
}

// MARK: - Chunked recognizer

/// Transcribes a recording in overlapping windows through
/// `SFSpeechURLRecognitionRequest`, which fails on a long file. Each window
/// keeps its own request, and the recognized speech is placed back on the
/// recording timeline. This is the path for a Mac without `SpeechAnalyzer`.
@MainActor
final class ChunkedSpeechFileTranscriber: SpeechFileTranscribing {
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isCancelled = false

    func transcribe(
        audioURL: URL,
        locale: Locale,
        onProgress: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment] {
        isCancelled = false
        guard await SpeechAuthorization.request() == .authorized else {
            throw SpeechTranscriptionError.permissionDenied
        }
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechTranscriptionError.unavailable
        }
        guard recognizer.supportsOnDeviceRecognition else {
            throw SpeechTranscriptionError.onDeviceUnavailable
        }

        let duration = try SpeechAudioWindow.duration(of: audioURL)
        let windows = SpeechAudioWindow.windows(covering: duration)
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("Atrium-Transcription-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        var recognized: [SpeechRecognitionSegment] = []
        var lastError: Error?
        for window in windows {
            if isCancelled || Task.isCancelled { throw CancellationError() }
            do {
                let chunkURL = folder.appendingPathComponent("window-\(window.index).wav")
                try await SpeechAudioWindow.extract(window, from: audioURL, to: chunkURL)
                let chunk = try await recognize(chunkURL, using: recognizer)
                recognized.append(
                    contentsOf: SpeechAudioWindow.place(chunk, in: window, of: windows.count)
                )
                onProgress(recognized)
                DiagnosticLogger.progress(
                    operation: "file_transcribe_window",
                    measure: "window=\(window.index + 1)/\(windows.count)"
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // A window that fails must not discard the windows that worked.
                lastError = error
                DiagnosticLogger.partialFailure(
                    operation: "file_transcribe_window",
                    error: error,
                    context: "window=\(window.index + 1)/\(windows.count)"
                )
            }
        }
        if recognized.isEmpty, let lastError {
            throw SpeechTranscriptionError.failed(lastError.localizedDescription)
        }
        return recognized
    }

    func cancel() {
        isCancelled = true
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    private func recognize(
        _ audioURL: URL,
        using recognizer: SFSpeechRecognizer
    ) async throws -> [SpeechRecognitionSegment] {
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true
        request.addsPunctuation = true
        return try await withCheckedThrowingContinuation { continuation in
            let completion = RecognitionCompletion(continuation: continuation)
            recognitionTask = recognizer.recognitionTask(
                with: request,
                resultHandler: makeWindowHandler(completion: completion)
            )
        }
    }
}

private func makeWindowHandler(
    completion: RecognitionCompletion
) -> (SFSpeechRecognitionResult?, (any Error)?) -> Void {
    { result, error in
        if let error {
            completion.fail(SpeechTranscriptionError.failed(error.localizedDescription))
            return
        }
        guard let result, result.isFinal else { return }
        let segments: [SpeechRecognitionSegment] = result.bestTranscription.segments.compactMap { segment in
            let text = segment.substring.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return SpeechRecognitionSegment(
                text: text,
                startTime: segment.timestamp,
                duration: segment.duration
            )
        }
        completion.succeed(segments)
    }
}

private final class RecognitionCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<[SpeechRecognitionSegment], Error>?

    init(continuation: CheckedContinuation<[SpeechRecognitionSegment], Error>) {
        self.continuation = continuation
    }

    func succeed(_ value: [SpeechRecognitionSegment]) {
        finish(.success(value))
    }

    func fail(_ error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<[SpeechRecognitionSegment], Error>) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }
}

// MARK: - Windows

/// Splits a recording into overlapping windows and places recognized speech
/// back on the recording timeline.
enum SpeechAudioWindow {
    /// Long enough to hold a full thought, short enough for one request.
    static let length: Double = 45
    /// Shared audio at each seam, so a word across the seam is still recognized.
    static let overlap: Double = 2

    struct Window: Equatable, Sendable {
        let index: Int
        let start: Double
        let duration: Double

        var end: Double { start + duration }
    }

    static func windows(
        covering duration: Double,
        length: Double = Self.length,
        overlap: Double = Self.overlap
    ) -> [Window] {
        guard duration > 0 else { return [] }
        guard duration > length else {
            return [Window(index: 0, start: 0, duration: duration)]
        }
        let stride = max(1, length - overlap)
        var windows: [Window] = []
        var start: Double = 0
        while start < duration {
            let remaining = duration - start
            windows.append(
                Window(index: windows.count, start: start, duration: min(length, remaining))
            )
            if remaining <= length { break }
            start += stride
        }
        return windows
    }

    /// Moves window-relative timing onto the recording timeline and drops the
    /// speech that a neighbouring window already owns.
    static func place(
        _ recognized: [SpeechRecognitionSegment],
        in window: Window,
        of windowCount: Int,
        overlap: Double = Self.overlap
    ) -> [SpeechRecognitionSegment] {
        let isFirst = window.index == 0
        let isLast = window.index == windowCount - 1
        let lower = isFirst ? -.infinity : window.start + overlap / 2
        let upper = isLast ? .infinity : window.end - overlap / 2
        return recognized.compactMap { segment in
            let start = window.start + segment.startTime
            let middle = start + segment.duration / 2
            guard middle >= lower, middle < upper else { return nil }
            return SpeechRecognitionSegment(
                text: segment.text,
                startTime: start,
                duration: segment.duration
            )
        }
    }

    static func duration(of audioURL: URL) throws -> Double {
        let file = try AVAudioFile(forReading: audioURL)
        guard file.processingFormat.sampleRate > 0 else {
            throw SpeechTranscriptionError.failed("Atrium could not read the saved audio.")
        }
        return Double(file.length) / file.processingFormat.sampleRate
    }

    /// Writes one window to its own uncompressed file for recognition.
    static func extract(_ window: Window, from audioURL: URL, to destination: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            let source = try AVAudioFile(forReading: audioURL)
            let format = source.processingFormat
            let start = AVAudioFramePosition(window.start * format.sampleRate)
            let frames = AVAudioFrameCount(min(window.duration * format.sampleRate, Double(source.length - start)))
            guard frames > 0 else {
                throw SpeechTranscriptionError.failed("Atrium could not read the saved audio.")
            }
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
                throw SpeechTranscriptionError.failed("Atrium could not read the saved audio.")
            }
            source.framePosition = start
            try source.read(into: buffer, frameCount: frames)
            let output = try AVAudioFile(
                forWriting: destination,
                settings: format.settings,
                commonFormat: format.commonFormat,
                interleaved: format.isInterleaved
            )
            try output.write(from: buffer)
        }.value
    }
}
