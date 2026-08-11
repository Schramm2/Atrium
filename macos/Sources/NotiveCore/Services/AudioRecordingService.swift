import Foundation

public enum AudioRecordingError: LocalizedError {
    case permissionDenied
    case couldNotStart
    case noActiveRecording
    case alreadyRecording

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Microphone access is required to record meetings or use Dictation."
        case .couldNotStart:
            "Notive could not start the microphone recording."
        case .noActiveRecording:
            "There is no active recording to stop."
        case .alreadyRecording:
            "An audio recording is already active."
        }
    }
}
