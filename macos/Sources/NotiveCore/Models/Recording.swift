import Foundation

public enum RecordingState: Equatable, Sendable {
    case idle
    case recording
    case paused
    case transcribing
    case failed(String)
}

public struct SpeechRecognitionSegment: Hashable, Sendable {
    public let text: String
    public let startTime: Double
    public let duration: Double

    public init(text: String, startTime: Double, duration: Double) {
        self.text = text
        self.startTime = startTime
        self.duration = duration
    }
}
