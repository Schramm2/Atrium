@testable import NotiveCore
import Foundation
import Testing

@Suite("Company Hub boundaries")
struct CompanyHubTests {
    @Test("A disconnected hub loads no shared content")
    @MainActor
    func disconnectedReadsAreEmpty() async {
        let store = CompanyHubStore()

        #expect(!store.isConnected)

        await store.loadHomeScreen()
        await store.loadSharedItems()

        #expect(!store.hasSharedContent)
        #expect(store.stats.isEmpty)
        #expect(store.attention.isEmpty)
        #expect(store.sharedToday.isEmpty)
        #expect(store.sharedItems.isEmpty)
        #expect(store.agents.isEmpty)
        #expect(store.activity.isEmpty)
        #expect(store.people.isEmpty)
        #expect(store.unreadActivityCount == 0)
        #expect(store.runningAgentCount == 0)
        #expect(store.errorMessage == nil)
    }

    @Test("A disconnected hub reports why sharing a meeting failed")
    @MainActor
    func disconnectedWriteReportsUnavailable() async {
        let store = CompanyHubStore()

        await store.setShared(true, meetingID: "meeting-1")

        #expect(store.errorMessage == CompanyHubUnavailableError().errorDescription)

        store.clearError()
        #expect(store.errorMessage == nil)
    }

    @Test("An empty query clears search results without calling the provider")
    @MainActor
    func emptyQuerySkipsSearch() async {
        let store = CompanyHubStore(service: RecordingHubService())

        store.searchQuery = "   "
        await store.search()

        #expect(store.searchGroups.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test("A connected hub fills every screen from its provider")
    @MainActor
    func connectedReadsPopulateState() async {
        let store = CompanyHubStore(service: RecordingHubService())

        await store.loadCompanyScreen()
        await store.loadAgents()
        await store.loadActivity()

        #expect(store.isConnected)
        #expect(store.agents.count == 1)
        #expect(store.selectedAgent?.id == "agent-1")
        #expect(store.runningAgentCount == 1)
        #expect(store.unreadActivityCount == 1)
        #expect(store.thread.count == 1)
    }

    @Test("The Home screen loads the local and shared collections it shows")
    @MainActor
    func homeScreenReadsPopulateState() async {
        let store = CompanyHubStore(service: RecordingHubService())

        await store.loadHomeScreen()

        #expect(store.hasSharedContent)
        #expect(store.stats.count == 1)
        #expect(store.attention.count == 1)
        #expect(store.attention.first?.destination == .agents)
        #expect(store.sharedToday.count == 1)
        #expect(store.agents.count == 1)
        #expect(store.people.count == 1)
        #expect(store.activity.count == 1)
        #expect(store.errorMessage == nil)
    }

    @Test("Sending a message reloads the thread it was sent to")
    @MainActor
    func sendReloadsThread() async {
        let service = RecordingHubService()
        let store = CompanyHubStore(service: service)
        await store.loadAgents()

        await store.send("  Post the action items  ")

        #expect(await service.sentMessages == ["Post the action items"])
        #expect(store.errorMessage == nil)
    }

    @Test("The shared item filter selects by kind")
    func filterSelectsByKind() {
        let meeting = Self.item(id: "a", kind: .meeting)
        let note = Self.item(id: "b", kind: .note)
        let brief = Self.item(id: "c", kind: .brief)
        let agentNote = Self.item(id: "d", kind: .agentNote)
        let all = [meeting, note, brief, agentNote]

        #expect(all.filter(HubItemFilter.all.accepts).count == 4)
        #expect(all.filter(HubItemFilter.meetings.accepts) == [meeting])
        #expect(all.filter(HubItemFilter.notes.accepts) == [note])
        #expect(all.filter(HubItemFilter.agentOutput.accepts) == [brief, agentNote])
    }

    private static func item(id: String, kind: HubItemKind) -> HubItem {
        HubItem(
            id: id,
            title: "Item \(id)",
            excerpt: "",
            sharedBy: "Someone",
            sharedByInitials: "SO",
            kind: kind,
            sharedAt: Date(timeIntervalSince1970: 0),
            tint: .accent
        )
    }
}

/// A connected provider that returns one of everything and records what was sent.
private actor RecordingHubService: CompanyHubProviding {
    private(set) var sentMessages: [String] = []

    nonisolated var isConnected: Bool { true }

    func loadStats() -> [HubStat] {
        [HubStat(id: "s1", label: "Shared this week", value: "1", delta: "", tone: .neutral)]
    }

    func loadAttention() -> [HubAttentionItem] {
        [
            HubAttentionItem(
                id: "a1",
                title: "Revised pricing sheet",
                detail: "Escalated by an agent",
                tag: "Due Thu",
                tone: .warning,
                symbolName: "bolt.fill",
                destination: .agents
            )
        ]
    }

    func loadSharedToday() -> [HubItem] { [Self.item] }
    func loadSharedItems() -> [HubItem] { [Self.item] }

    func loadAgents() -> [HubAgent] {
        [
            HubAgent(
                id: "agent-1",
                name: "Agent",
                initials: "AG",
                role: "Ops",
                task: "",
                detail: "",
                runsToday: 1,
                lastRun: nil,
                status: .running,
                tint: .accent
            )
        ]
    }

    func loadThread(agentID: String) -> [HubAgentMessage] {
        [
            HubAgentMessage(
                id: "m1",
                author: "You",
                sentAt: Date(timeIntervalSince1970: 0),
                text: "Hello",
                origin: .you
            )
        ]
    }

    func loadPeople() -> [HubPerson] {
        [
            HubPerson(
                id: "p1",
                name: "Person",
                initials: "PE",
                role: "Role",
                company: "Ubundi",
                focus: "",
                status: "Active",
                statusTone: .success,
                tint: .accent,
                isAgent: false
            )
        ]
    }

    func loadActivity() -> [HubActivityEvent] {
        [
            HubActivityEvent(
                id: "e1",
                who: "Person",
                what: "shared a meeting",
                detail: nil,
                occurredAt: Date(timeIntervalSince1970: 0),
                tint: .accent,
                isRead: false
            )
        ]
    }

    func search(_ query: String) -> [HubSearchGroup] {
        [HubSearchGroup(id: "g1", label: "Meetings", results: [])]
    }

    func send(_ text: String, toAgent agentID: String) {
        sentMessages.append(text)
    }

    func markAllActivityRead() {}
    func setShared(_ isShared: Bool, meetingID: String) {}

    private static let item = HubItem(
        id: "i1",
        title: "Item",
        excerpt: "",
        sharedBy: "Person",
        sharedByInitials: "PE",
        kind: .meeting,
        sharedAt: Date(timeIntervalSince1970: 0),
        tint: .accent
    )
}
