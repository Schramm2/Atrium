import Foundation

public enum AudioRecordingError: LocalizedError {
    case permissionDenied
    case couldNotStart
    case noActiveRecording

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Microphone access is required to record a meeting."
        case .couldNotStart:
            "Notive could not start the microphone recording."
        case .noActiveRecording:
            "There is no active recording to stop."
        }
    }
}
