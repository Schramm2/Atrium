import Foundation

public struct AskScope: Equatable, Sendable {
    public var meetingIDs: Set<String>
    public var dateFrom: Date?
    public var dateTo: Date?

    public init(
        meetingIDs: Set<String> = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) {
        self.meetingIDs = meetingIDs
        self.dateFrom = dateFrom
        self.dateTo = dateTo
    }
}

public struct AskEvidence: Identifiable, Hashable, Sendable {
    public let id: String
    public let meetingID: String
    public let meetingTitle: String
    public let transcriptID: String
    public let snippet: String
    public let context: String
    public let speaker: String?
    public let timestamp: String
    public let audioStartTime: Double?
    public let meetingCreatedAt: Date
    public let score: Double

    public init(
        id: String,
        meetingID: String,
        meetingTitle: String,
        transcriptID: String,
        snippet: String,
        context: String,
        speaker: String? = nil,
        timestamp: String,
        audioStartTime: Double? = nil,
        meetingCreatedAt: Date,
        score: Double
    ) {
        self.id = id
        self.meetingID = meetingID
        self.meetingTitle = meetingTitle
        self.transcriptID = transcriptID
        self.snippet = snippet
        self.context = context
        self.speaker = speaker
        self.timestamp = timestamp
        self.audioStartTime = audioStartTime
        self.meetingCreatedAt = meetingCreatedAt
        self.score = score
    }
}

public struct AskClaim: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let text: String
    public let citationIDs: [String]

    public init(id: UUID = UUID(), text: String, citationIDs: [String]) {
        self.id = id
        self.text = text
        self.citationIDs = citationIDs
    }
}

public struct AskAnswer: Equatable, Sendable {
    public let claims: [AskClaim]
    public let citations: [AskEvidence]
    public let provider: String
    public let model: String

    public init(
        claims: [AskClaim],
        citations: [AskEvidence],
        provider: String,
        model: String
    ) {
        self.claims = claims
        self.citations = citations
        self.provider = provider
        self.model = model
    }
}

public enum AskPhase: Equatable, Sendable {
    case idle
    case retrieving
    case confirming(String)
    case generating
    case answered
    case insufficient
    case failed(String)
}
