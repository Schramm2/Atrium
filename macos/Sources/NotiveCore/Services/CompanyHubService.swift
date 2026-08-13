import Foundation

/// The shared workspace behind the Company Hub screens.
///
/// No implementation exists yet. `DisconnectedCompanyHubService` is the default: reads return
/// nothing and writes report that the hub is not connected. To implement the Company Hub,
/// provide a type that conforms to this protocol and pass it to `CompanyHubStore`.
///
/// Every member is asynchronous and throwing so a network or cross-device implementation needs
/// no change to the calling interface.
public protocol CompanyHubProviding: Sendable {
    /// `false` until a shared workspace is connected. The interface uses this to explain why
    /// each screen is empty, and to disable actions that would publish to the hub.
    var isConnected: Bool { get }

    func loadStats() async throws -> [HubStat]
    func loadAttention() async throws -> [HubAttentionItem]
    func loadSharedToday() async throws -> [HubItem]
    func loadSharedItems() async throws -> [HubItem]
    func loadAgents() async throws -> [HubAgent]
    func loadThread(agentID: String) async throws -> [HubAgentMessage]
    func loadPeople() async throws -> [HubPerson]
    func loadActivity() async throws -> [HubActivityEvent]
    func search(_ query: String) async throws -> [HubSearchGroup]

    func send(_ text: String, toAgent agentID: String) async throws
    func markAllActivityRead() async throws
    func setShared(_ isShared: Bool, meetingID: String) async throws
}

/// Reported by writes while no shared workspace is connected.
public struct CompanyHubUnavailableError: LocalizedError, Sendable {
    public init() {}

    public var errorDescription: String? {
        "The Company Hub is not connected."
    }

    public var recoverySuggestion: String? {
        "Connect a shared workspace to share items, message agents, and see company activity."
    }
}

/// Default provider. Reads are empty and writes report `CompanyHubUnavailableError`.
public struct DisconnectedCompanyHubService: CompanyHubProviding {
    public init() {}

    public var isConnected: Bool { false }

    public func loadStats() async throws -> [HubStat] { [] }
    public func loadAttention() async throws -> [HubAttentionItem] { [] }
    public func loadSharedToday() async throws -> [HubItem] { [] }
    public func loadSharedItems() async throws -> [HubItem] { [] }
    public func loadAgents() async throws -> [HubAgent] { [] }
    public func loadThread(agentID: String) async throws -> [HubAgentMessage] { [] }
    public func loadPeople() async throws -> [HubPerson] { [] }
    public func loadActivity() async throws -> [HubActivityEvent] { [] }
    public func search(_ query: String) async throws -> [HubSearchGroup] { [] }

    public func send(_ text: String, toAgent agentID: String) async throws {
        throw CompanyHubUnavailableError()
    }

    public func markAllActivityRead() async throws {
        throw CompanyHubUnavailableError()
    }

    public func setShared(_ isShared: Bool, meetingID: String) async throws {
        throw CompanyHubUnavailableError()
    }
}
