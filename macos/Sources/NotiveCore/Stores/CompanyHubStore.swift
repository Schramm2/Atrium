import Foundation
import Observation

/// State for the Company Hub screens.
///
/// Every collection stays empty until a `CompanyHubProviding` implementation is connected.
/// The screens read this store directly and show an empty state when a collection is empty.
@MainActor
@Observable
public final class CompanyHubStore {
    public private(set) var stats: [HubStat] = []
    public private(set) var sharedToday: [HubItem] = []
    public private(set) var sharedItems: [HubItem] = []
    public private(set) var agents: [HubAgent] = []
    public private(set) var thread: [HubAgentMessage] = []
    public private(set) var people: [HubPerson] = []
    public private(set) var activity: [HubActivityEvent] = []
    public private(set) var searchGroups: [HubSearchGroup] = []
    public private(set) var isLoading = false

    public var selectedAgentID: String?
    public var itemFilter: HubItemFilter = .all
    public var searchQuery = ""
    public var errorMessage: String?

    @ObservationIgnored private let service: any CompanyHubProviding

    public init(service: any CompanyHubProviding = DisconnectedCompanyHubService()) {
        self.service = service
    }

    /// `false` until a shared workspace is connected.
    public var isConnected: Bool { service.isConnected }

    public var selectedAgent: HubAgent? {
        guard let selectedAgentID else { return agents.first }
        return agents.first { $0.id == selectedAgentID } ?? agents.first
    }

    public var visibleSharedItems: [HubItem] {
        sharedItems.filter(itemFilter.accepts)
    }

    public var unreadActivityCount: Int {
        activity.count { !$0.isRead }
    }

    public var runningAgentCount: Int {
        agents.count { $0.status == .running }
    }

    // MARK: - Reads

    public func loadCompanyScreen() async {
        await load {
            async let stats = self.service.loadStats()
            async let shared = self.service.loadSharedToday()
            async let agents = self.service.loadAgents()
            async let activity = self.service.loadActivity()
            self.stats = try await stats
            self.sharedToday = try await shared
            self.agents = try await agents
            self.activity = try await activity
        }
    }

    public func loadAgents() async {
        await load {
            self.agents = try await self.service.loadAgents()
            if self.selectedAgentID == nil { self.selectedAgentID = self.agents.first?.id }
            await self.loadThread()
        }
    }

    public func loadThread() async {
        guard let id = selectedAgent?.id else {
            thread = []
            return
        }
        await load { self.thread = try await self.service.loadThread(agentID: id) }
    }

    public func loadSharedItems() async {
        await load { self.sharedItems = try await self.service.loadSharedItems() }
    }

    public func loadPeople() async {
        await load { self.people = try await self.service.loadPeople() }
    }

    public func loadActivity() async {
        await load { self.activity = try await self.service.loadActivity() }
    }

    public func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchGroups = []
            return
        }
        await load { self.searchGroups = try await self.service.search(query) }
    }

    // MARK: - Writes

    public func send(_ text: String) async {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, let id = selectedAgent?.id else { return }
        await load {
            try await self.service.send(message, toAgent: id)
            self.thread = try await self.service.loadThread(agentID: id)
        }
    }

    public func markAllActivityRead() async {
        await load {
            try await self.service.markAllActivityRead()
            self.activity = try await self.service.loadActivity()
        }
    }

    public func setShared(_ isShared: Bool, meetingID: String) async {
        await load { try await self.service.setShared(isShared, meetingID: meetingID) }
    }

    public func clearError() {
        errorMessage = nil
    }

    private func load(_ work: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await work()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            DiagnosticLogger.failure(operation: "company_hub_load", error: error)
        }
    }
}
