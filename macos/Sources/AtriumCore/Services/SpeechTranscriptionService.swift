import Foundation
import Speech

@MainActor
public protocol SpeechTranscribing: AnyObject {
    func requestPermission() async -> Bool
    func transcribe(
        audioURL: URL,
        localeIdentifier: String
    ) async throws -> [SpeechRecognitionSegment]
    func cancel()
}

public enum SpeechTranscriptionError: LocalizedError {
    case permissionDenied
    case unavailable
    case onDeviceUnavailable
    case noSpeech
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Speech Recognition access is required to transcribe audio."
        case .unavailable:
            "Speech recognition is unavailable for the selected language."
        case .onDeviceUnavailable:
            "On-device speech recognition is unavailable for the selected language."
        case .noSpeech:
            "Atrium did not find speech in this audio."
        case let .failed(message):
            "Transcription failed: \(message)"
        }
    }
}

@MainActor
public final class SpeechTranscriptionService: SpeechTranscribing {
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionCompletion: RecognitionCompletion?
    private var isTranscribing = false
    private var cancellationRequested = false

    public init() {}

    public func requestPermission() async -> Bool {
        await authorizationStatus() == .authorized
    }

    public func transcribe(
        audioURL: URL,
        localeIdentifier: String = Locale.current.identifier
    ) async throws -> [SpeechRecognitionSegment] {
        guard !isTranscribing else {
            throw SpeechTranscriptionError.failed("Another transcription is already in progress.")
        }
        isTranscribing = true
        cancellationRequested = false
        defer {
            isTranscribing = false
            cancellationRequested = false
            recognitionTask = nil
            recognitionCompletion = nil
        }
        let authorization = await authorizationStatus()
        guard !cancellationRequested, !Task.isCancelled else { throw CancellationError() }
        guard authorization == .authorized else {
            throw SpeechTranscriptionError.permissionDenied
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)),
              recognizer.isAvailable else {
            throw SpeechTranscriptionError.unavailable
        }
        guard recognizer.supportsOnDeviceRecognition else {
            throw SpeechTranscriptionError.onDeviceUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true
        request.addsPunctuation = true

        return try await withCheckedThrowingContinuation { continuation in
            let completion = RecognitionCompletion(continuation: continuation)
            recognitionCompletion = completion
            recognitionTask = recognizer.recognitionTask(
                with: request,
                resultHandler: makeTranscriptionHandler(completion: completion)
            )
        }
    }

    public func cancel() {
        guard isTranscribing else { return }
        cancellationRequested = true
        recognitionCompletion?.fail(CancellationError())
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionCompletion = nil
    }

    private func authorizationStatus() async -> SFSpeechRecognizerAuthorizationStatus {
        await SpeechAuthorization.request()
    }
}

private func makeTranscriptionHandler(
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
        if segments.isEmpty {
            completion.fail(SpeechTranscriptionError.noSpeech)
        } else {
            completion.succeed(segments)
        }
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
