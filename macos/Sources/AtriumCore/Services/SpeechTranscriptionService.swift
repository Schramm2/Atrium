import Foundation
@preconcurrency import Speech

@MainActor
public protocol SpeechTranscribing: AnyObject {
    func requestPermission() async -> Bool

    /// Transcribes a saved recording of any length.
    ///
    /// `onProgress` receives every segment recognized so far, so a caller can
    /// save the transcript while the work continues and keep what arrived when
    /// a later part fails.
    func transcribe(
        audioURL: URL,
        localeIdentifier: String,
        onProgress: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment]

    func cancel()
}

extension SpeechTranscribing {
    public func transcribe(
        audioURL: URL,
        localeIdentifier: String = Locale.current.identifier
    ) async throws -> [SpeechRecognitionSegment] {
        try await transcribe(
            audioURL: audioURL,
            localeIdentifier: localeIdentifier,
            onProgress: { _ in }
        )
    }
}

public enum SpeechTranscriptionError: UserPresentableError {
    case permissionDenied
    case unavailable
    case onDeviceUnavailable
    case modelUnavailable
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
        case .modelUnavailable:
            "The on-device speech model for the selected language is not installed."
        case .noSpeech:
            "Atrium did not find speech in this audio."
        case let .failed(message):
            "Transcription failed: \(message)"
        }
    }

    public var diagnosticCode: String {
        switch self {
        case .permissionDenied: "speech_permission_denied"
        case .unavailable: "speech_unavailable"
        case .onDeviceUnavailable: "speech_on_device_unavailable"
        case .modelUnavailable: "speech_model_unavailable"
        case .noSpeech: "speech_no_speech"
        case .failed: "speech_failed"
        }
    }
}

/// Transcribes saved recordings on this Mac.
///
/// macOS 26 and later read the whole recording through `SpeechAnalyzer`. Older
/// systems fall back to overlapping `SFSpeechRecognizer` windows, because one
/// request over a long file fails part of the way through.
@MainActor
public final class SpeechTranscriptionService: SpeechTranscribing {
    private var engine: (any SpeechFileTranscribing)?
    private var isTranscribing = false
    private var cancellationRequested = false

    public init() {}

    public func requestPermission() async -> Bool {
        // Live capture during a meeting still uses Speech Recognition, so keep
        // asking for it. A refusal does not block file transcription when the
        // speech analyzer is available, because that interface needs no consent.
        let status = await SpeechAuthorization.request()
        if status == .authorized { return true }
        return Self.usesSpeechAnalyzer
    }

    public func transcribe(
        audioURL: URL,
        localeIdentifier: String,
        onProgress: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment] {
        guard !isTranscribing else {
            throw SpeechTranscriptionError.failed("Another transcription is already in progress.")
        }
        isTranscribing = true
        cancellationRequested = false
        defer {
            isTranscribing = false
            cancellationRequested = false
            engine = nil
        }
        let engine = Self.makeEngine()
        self.engine = engine
        guard !cancellationRequested, !Task.isCancelled else { throw CancellationError() }
        let recognized = try await engine.transcribe(
            audioURL: audioURL,
            locale: Locale(identifier: localeIdentifier),
            onProgress: onProgress
        )
        guard !cancellationRequested, !Task.isCancelled else { throw CancellationError() }
        guard !recognized.isEmpty else { throw SpeechTranscriptionError.noSpeech }
        return recognized
    }

    public func cancel() {
        guard isTranscribing else { return }
        cancellationRequested = true
        engine?.cancel()
        engine = nil
    }

    static var usesSpeechAnalyzer: Bool {
        if #available(macOS 26, *) {
            return SpeechTranscriber.isAvailable
        }
        return false
    }

    private static func makeEngine() -> any SpeechFileTranscribing {
        if #available(macOS 26, *), SpeechTranscriber.isAvailable {
            return SpeechAnalyzerFileTranscriber()
        }
        return ChunkedSpeechFileTranscriber()
    }
}
