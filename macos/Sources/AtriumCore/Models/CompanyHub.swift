import Foundation

/// Types for the Company Hub — the shared workspace across Ubundi and First Motive.
///
/// The Company Hub user interface is complete. No shared workspace service exists yet, so
/// `CompanyHubStore` holds empty collections until an implementation of `CompanyHubProviding`
/// is connected. These types define the contract that implementation must satisfy.

/// Accent role for a Company Hub item, resolved against the active brand palette by the interface.
public enum HubTint: String, Sendable, Codable {
    case accent
    case secondaryAccent
    case ai
}

/// Semantic tone for a status or trend value.
public enum HubTone: String, Sendable, Codable {
    case success
    case warning
    case neutral
}

public enum HubAgentStatus: String, Sendable, Codable {
    case running
    case idle

    public var title: String {
        switch self {
        case .running: "Running"
        case .idle: "Idle"
        }
    }
}

/// One headline number on the Company screen.
public struct HubStat: Identifiable, Sendable, Hashable {
    public let id: String
    public let label: String
    public let value: String
    public let delta: String
    public let tone: HubTone

    public init(id: String, label: String, value: String, delta: String, tone: HubTone) {
        self.id = id
        self.label = label
        self.value = value
        self.delta = delta
        self.tone = tone
    }
}

/// Where an attention item opens when a person selects it.
public enum HubAttentionDestination: String, Sendable, Codable {
    case agents
    case sharedContext
    case activity
}

/// One item on the Home screen that waits for a person to act.
public struct HubAttentionItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let detail: String
    public let tag: String
    public let tone: HubTone
    public let symbolName: String
    public let destination: HubAttentionDestination

    public init(
        id: String,
        title: String,
        detail: String,
        tag: String,
        tone: HubTone,
        symbolName: String,
        destination: HubAttentionDestination
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.tag = tag
        self.tone = tone
        self.symbolName = symbolName
        self.destination = destination
    }
}

/// An item another person or agent shared to the hub.
public struct HubItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let excerpt: String
    public let sharedBy: String
    public let sharedByInitials: String
    public let kind: HubItemKind
    public let sharedAt: Date
    public let tint: HubTint

    public init(
        id: String,
        title: String,
        excerpt: String,
        sharedBy: String,
        sharedByInitials: String,
        kind: HubItemKind,
        sharedAt: Date,
        tint: HubTint
    ) {
        self.id = id
        self.title = title
        self.excerpt = excerpt
        self.sharedBy = sharedBy
        self.sharedByInitials = sharedByInitials
        self.kind = kind
        self.sharedAt = sharedAt
        self.tint = tint
    }
}

public enum HubItemKind: String, Sendable, Codable, CaseIterable {
    case meeting
    case note
    case agentNote
    case brief

    public var title: String {
        switch self {
        case .meeting: "Meeting"
        case .note: "Note"
        case .agentNote: "Agent note"
        case .brief: "Brief"
        }
    }

    public var symbolName: String {
        switch self {
        case .meeting: "text.bubble"
        case .note: "note.text"
        case .agentNote, .brief: "bolt.fill"
        }
    }
}

/// Filter applied to the Shared Context list.
public enum HubItemFilter: String, Sendable, CaseIterable, Identifiable {
    case all
    case meetings
    case notes
    case agentOutput

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: "All"
        case .meetings: "Meetings"
        case .notes: "Notes"
        case .agentOutput: "Agent output"
        }
    }

    public func accepts(_ item: HubItem) -> Bool {
        switch self {
        case .all: true
        case .meetings: item.kind == .meeting
        case .notes: item.kind == .note
        case .agentOutput: item.kind == .agentNote || item.kind == .brief
        }
    }
}

/// A company agent that works alongside the team.
public struct HubAgent: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let initials: String
    public let role: String
    public let task: String
    public let detail: String
    public let runsToday: Int
    public let lastRun: Date?
    public let status: HubAgentStatus
    public let tint: HubTint

    public init(
        id: String,
        name: String,
        initials: String,
        role: String,
        task: String,
        detail: String,
        runsToday: Int,
        lastRun: Date?,
        status: HubAgentStatus,
        tint: HubTint
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.role = role
        self.task = task
        self.detail = detail
        self.runsToday = runsToday
        self.lastRun = lastRun
        self.status = status
        self.tint = tint
    }
}

/// One message in a company-visible agent thread.
public struct HubAgentMessage: Identifiable, Sendable, Hashable {
    public enum Origin: String, Sendable, Codable {
        case you
        case teammate
        case agent
    }

    public let id: String
    public let author: String
    public let sentAt: Date
    public let text: String
    public let origin: Origin

    public init(id: String, author: String, sentAt: Date, text: String, origin: Origin) {
        self.id = id
        self.author = author
        self.sentAt = sentAt
        self.text = text
        self.origin = origin
    }
}

/// A person or agent in the shared workspace.
public struct HubPerson: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let initials: String
    public let role: String
    public let company: String
    public let focus: String
    public let status: String
    public let statusTone: HubTone
    public let tint: HubTint
    public let isAgent: Bool

    public init(
        id: String,
        name: String,
        initials: String,
        role: String,
        company: String,
        focus: String,
        status: String,
        statusTone: HubTone,
        tint: HubTint,
        isAgent: Bool
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.role = role
        self.company = company
        self.focus = focus
        self.status = status
        self.statusTone = statusTone
        self.tint = tint
        self.isAgent = isAgent
    }
}

/// One entry in the shared workspace activity feed.
public struct HubActivityEvent: Identifiable, Sendable, Hashable {
    public let id: String
    public let who: String
    public let what: String
    public let detail: String?
    public let occurredAt: Date
    public let tint: HubTint
    public let isRead: Bool

    public init(
        id: String,
        who: String,
        what: String,
        detail: String?,
        occurredAt: Date,
        tint: HubTint,
        isRead: Bool
    ) {
        self.id = id
        self.who = who
        self.what = what
        self.detail = detail
        self.occurredAt = occurredAt
        self.tint = tint
        self.isRead = isRead
    }
}

/// One labelled group of hub search results.
public struct HubSearchGroup: Identifiable, Sendable, Hashable {
    public let id: String
    public let label: String
    public let results: [HubSearchResult]

    public init(id: String, label: String, results: [HubSearchResult]) {
        self.id = id
        self.label = label
        self.results = results
    }
}

public struct HubSearchResult: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let snippet: String
    public let source: String
    public let symbolName: String

    public init(id: String, title: String, snippet: String, source: String, symbolName: String) {
        self.id = id
        self.title = title
        self.snippet = snippet
        self.source = source
        self.symbolName = symbolName
    }
}
