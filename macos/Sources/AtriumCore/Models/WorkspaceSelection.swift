import Foundation

public enum WorkspaceSelection: Hashable, Sendable {
    case home
    case ask
    case dictation
    case notes
    case meeting(String)
    case company
    case agents
    case sharedContext
    case people
    case search
    case activity
}

public enum BrandTheme: String, CaseIterable, Identifiable, Sendable {
    case ubundi
    case firstMotive = "first-motive"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .ubundi: "Ubundi"
        case .firstMotive: "First Motive"
        }
    }
}

public struct MeetingWorkspace: Sendable {
    public var meeting: Meeting
    public var transcripts: [TranscriptSegment]
    public var note: MeetingNote
    public var summary: MeetingSummary?
    public var aliases: [SpeakerAlias]

    public init(
        meeting: Meeting,
        transcripts: [TranscriptSegment],
        note: MeetingNote,
        summary: MeetingSummary?,
        aliases: [SpeakerAlias]
    ) {
        self.meeting = meeting
        self.transcripts = transcripts
        self.note = note
        self.summary = summary
        self.aliases = aliases
    }
}
