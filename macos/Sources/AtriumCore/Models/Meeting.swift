import Foundation

public struct Meeting: Identifiable, Hashable, Sendable {
    public let id: String
    public var title: String
    public let createdAt: Date
    public var updatedAt: Date
    public let folderPath: String?

    public init(
        id: String,
        title: String,
        createdAt: Date,
        updatedAt: Date,
        folderPath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folderPath = folderPath
    }
}

public struct TranscriptSegment: Identifiable, Hashable, Sendable {
    public let id: String
    public let meetingID: String
    public var text: String
    public let timestamp: String
    public let audioStartTime: Double?
    public let audioEndTime: Double?
    public let duration: Double?
    public let speaker: String?
    public let speakerDisplayName: String?

    public init(
        id: String,
        meetingID: String,
        text: String,
        timestamp: String,
        audioStartTime: Double? = nil,
        audioEndTime: Double? = nil,
        duration: Double? = nil,
        speaker: String? = nil,
        speakerDisplayName: String? = nil
    ) {
        self.id = id
        self.meetingID = meetingID
        self.text = text
        self.timestamp = timestamp
        self.audioStartTime = audioStartTime
        self.audioEndTime = audioEndTime
        self.duration = duration
        self.speaker = speaker
        self.speakerDisplayName = speakerDisplayName
    }

    public var resolvedSpeaker: String? {
        speakerDisplayName ?? speaker
    }
}

public struct MeetingNote: Equatable, Sendable {
    public let meetingID: String
    public var markdown: String
    public var json: String?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        meetingID: String,
        markdown: String,
        json: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.meetingID = meetingID
        self.markdown = markdown
        self.json = json
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct SpeakerAlias: Identifiable, Hashable, Sendable {
    public var id: String { "\(meetingID):\(originalLabel)" }
    public let meetingID: String
    public let originalLabel: String
    public var alias: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        meetingID: String,
        originalLabel: String,
        alias: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.meetingID = meetingID
        self.originalLabel = originalLabel
        self.alias = alias
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MeetingSummary: Equatable, Sendable {
    public let meetingID: String
    public var status: String
    public var markdown: String
    public var rawJSON: String
    public var error: String?

    public init(
        meetingID: String,
        status: String,
        markdown: String,
        rawJSON: String,
        error: String? = nil
    ) {
        self.meetingID = meetingID
        self.status = status
        self.markdown = markdown
        self.rawJSON = rawJSON
        self.error = error
    }
}

public struct TranscriptSearchResult: Identifiable, Hashable, Sendable {
    public let id: String
    public let meetingID: String
    public let meetingTitle: String
    public let context: String
    public let timestamp: String
    public let audioStartTime: Double?

    public init(
        id: String,
        meetingID: String,
        meetingTitle: String,
        context: String,
        timestamp: String,
        audioStartTime: Double? = nil
    ) {
        self.id = id
        self.meetingID = meetingID
        self.meetingTitle = meetingTitle
        self.context = context
        self.timestamp = timestamp
        self.audioStartTime = audioStartTime
    }
}
