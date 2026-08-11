import Foundation
import Testing
@testable import NotiveCore

@Suite("SQLite data compatibility")
struct SQLiteDatabaseTests {
    @Test("Meetings, transcripts, notes, summaries, and aliases round trip")
    func roundTrip() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let meeting = try database.createMeeting(title: "Design review")

        try database.insertTranscripts([
            TranscriptSegment(
                id: "segment-1",
                meetingID: meeting.id,
                text: "We decided to ship the local search first.",
                timestamp: "10:00:00",
                audioStartTime: 4,
                audioEndTime: 8,
                duration: 4,
                speaker: "Speaker 1"
            ),
            TranscriptSegment(
                id: "segment-2",
                meetingID: meeting.id,
                text: "Matthew will prepare the release notes.",
                timestamp: "10:00:08",
                audioStartTime: 8,
                audioEndTime: 12,
                duration: 4,
                speaker: "Speaker 1"
            ),
        ])
        try database.saveSpeakerAlias(
            meetingID: meeting.id,
            originalLabel: "Speaker 1",
            alias: "Matthew"
        )
        try database.saveNote(MeetingNote(meetingID: meeting.id, markdown: "# Context"))
        try database.saveSummary(meetingID: meeting.id, markdown: "# Summary\nLocal search ships first.")

        let meetings = try database.fetchMeetings()
        #expect(meetings.map(\.title) == ["Design review"])

        let transcripts = try database.fetchTranscripts(meetingID: meeting.id)
        #expect(transcripts.count == 2)
        #expect(transcripts.first?.resolvedSpeaker == "Matthew")
        #expect(try database.fetchNote(meetingID: meeting.id)?.markdown == "# Context")
        #expect(try database.fetchSummary(meetingID: meeting.id)?.markdown == "# Summary\nLocal search ships first.")
    }

    @Test("Search and Ask evidence stay local and scoped")
    func retrieval() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let included = try database.createMeeting(title: "Launch decision")
        let excluded = try database.createMeeting(title: "Other work")

        try database.insertTranscripts([
            TranscriptSegment(
                id: "included-1",
                meetingID: included.id,
                text: "The launch date is Friday.",
                timestamp: "09:00:00"
            ),
            TranscriptSegment(
                id: "excluded-1",
                meetingID: excluded.id,
                text: "The launch date is Monday.",
                timestamp: "11:00:00"
            ),
        ])

        let search = try database.search("Friday")
        #expect(search.count == 1)
        #expect(search.first?.meetingID == included.id)

        let evidence = try database.retrieveEvidence(
            question: "What launch date did we decide?",
            scope: AskScope(meetingIDs: [included.id])
        )
        #expect(evidence.count == 1)
        #expect(evidence.first?.id == "S1")
        #expect(evidence.first?.snippet.contains("Friday") == true)
    }

    @Test("Ask evidence ignores conversational query instructions")
    func retrievalIgnoresQueryInstructions() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let relevant = try database.createMeeting(title: "Relevant discussion")
        let unrelated = try database.createMeeting(title: "Other discussion")

        try database.insertTranscripts([
            TranscriptSegment(
                id: "relevant-1",
                meetingID: relevant.id,
                text: "Grounding keeps generated answers tied to meeting evidence.",
                timestamp: "09:00:00"
            ),
            TranscriptSegment(
                id: "unrelated-1",
                meetingID: unrelated.id,
                text: "Tell us more. Say it again. Discuss it with everyone.",
                timestamp: "11:00:00"
            ),
        ])

        let directEvidence = try database.retrieveEvidence(
            question: "grounding",
            scope: AskScope()
        )
        #expect(!directEvidence.isEmpty)
        #expect(directEvidence.allSatisfy { $0.meetingID == relevant.id })

        for question in [
            "Tell me about grounding",
            "What did we say about grounding?",
            "What did we discuss about grounding?",
        ] {
            let evidence = try database.retrieveEvidence(
                question: question,
                scope: AskScope()
            )
            let answer = LocalIntelligenceService.extractiveAnswer(evidence: evidence)

            #expect(!evidence.isEmpty, Comment(rawValue: question))
            #expect(
                evidence.allSatisfy { $0.meetingID == relevant.id },
                Comment(rawValue: question)
            )
            #expect(
                answer.citations.allSatisfy { $0.meetingID == relevant.id },
                Comment(rawValue: question)
            )
            #expect(answer.claims.flatMap(\.citationIDs).allSatisfy { citationID in
                answer.citations.contains { $0.id == citationID && $0.meetingID == relevant.id }
            }, Comment(rawValue: question))
        }
    }

    @Test("Ask infers a meeting title scope from the question")
    func retrievalInfersMeetingTitleScope() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let grounding = try database.createMeeting(title: "Grounding review")
        let unrelated = try database.createMeeting(title: "Other discussion")

        try database.insertTranscripts([
            TranscriptSegment(
                id: "grounding-1",
                meetingID: grounding.id,
                text: "Opening context established the customer problem.",
                timestamp: "09:00:00"
            ),
            TranscriptSegment(
                id: "grounding-2",
                meetingID: grounding.id,
                text: "Enterprise customers require stronger privacy controls.",
                timestamp: "09:05:00"
            ),
            TranscriptSegment(
                id: "grounding-3",
                meetingID: grounding.id,
                text: "The onboarding flow needs a simpler default path.",
                timestamp: "09:10:00"
            ),
            TranscriptSegment(
                id: "grounding-4",
                meetingID: grounding.id,
                text: "The final decision was to test both approaches.",
                timestamp: "09:15:00"
            ),
            TranscriptSegment(
                id: "grounding-filler",
                meetingID: grounding.id,
                text: "Okay.",
                timestamp: "09:20:00"
            ),
            TranscriptSegment(
                id: "unrelated-1",
                meetingID: unrelated.id,
                text: "Someone reviewed an unrelated topic several times.",
                timestamp: "11:00:00"
            ),
        ])

        let evidence = try database.retrieveEvidence(
            question: "Tell me about the Grounding review",
            scope: AskScope()
        )

        #expect(evidence.count == 4)
        #expect(evidence.allSatisfy { $0.meetingID == grounding.id })
        #expect(evidence.allSatisfy { $0.transcriptID != "grounding-filler" })
        #expect(evidence.contains { $0.snippet.contains("Opening context") })
        #expect(evidence.contains { $0.snippet.contains("final decision") })
    }

    @Test("Ask does not hard-scope a common topic to a matching title")
    func retrievalDoesNotInferCommonTopicAsTitleScope() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let planning = try database.createMeeting(title: "Launch planning")
        let operations = try database.createMeeting(title: "Operations")

        try database.insertTranscripts([
            TranscriptSegment(
                id: "planning-1",
                meetingID: planning.id,
                text: "The roadmap review is tomorrow.",
                timestamp: "09:00:00"
            ),
            TranscriptSegment(
                id: "operations-1",
                meetingID: operations.id,
                text: "We decided the launch date is Friday.",
                timestamp: "11:00:00"
            ),
        ])

        let evidence = try database.retrieveEvidence(
            question: "What did we decide about launch?",
            scope: AskScope()
        )

        #expect(!evidence.isEmpty)
        #expect(evidence.allSatisfy { $0.meetingID == operations.id })
    }

    @Test("Ask evidence stays diverse across meetings")
    func retrievalDiversifiesMeetings() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let dominant = try database.createMeeting(title: "Alpha")
        let secondary = try database.createMeeting(title: "Beta")

        let repeated = "delivery milestone delivery milestone delivery milestone"
        try database.insertTranscripts(
            (1...4).map { index in
                TranscriptSegment(
                    id: "dominant-\(index)",
                    meetingID: dominant.id,
                    text: repeated,
                    timestamp: "09:0\(index):00"
                )
            } + [
                TranscriptSegment(
                    id: "secondary-1",
                    meetingID: secondary.id,
                    text: "The delivery milestone is Friday.",
                    timestamp: "11:00:00"
                ),
            ]
        )

        let evidence = try database.retrieveEvidence(
            question: "delivery milestone",
            scope: AskScope(),
            limit: 4
        )
        let dominantCount = evidence.count { $0.meetingID == dominant.id }

        #expect(dominantCount <= 3)
        #expect(evidence.contains { $0.meetingID == secondary.id })
    }

    @Test("Ask context keeps the match and nearest same-meeting neighbors")
    func retrievalContextKeepsMatchAndNeighbors() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let relevant = try database.createMeeting(title: "Relevant")
        let interleaved = try database.createMeeting(title: "Interleaved")

        try database.insertTranscripts([
            TranscriptSegment(
                id: "relevant-before",
                meetingID: relevant.id,
                text: "Before " + String(repeating: "long context ", count: 100),
                timestamp: "09:00:00"
            ),
            TranscriptSegment(
                id: "other-before",
                meetingID: interleaved.id,
                text: "Wrong previous meeting context.",
                timestamp: "09:00:01"
            ),
            TranscriptSegment(
                id: "relevant-match",
                meetingID: relevant.id,
                text: "The unique grounding signal is evidence-backed citations.",
                timestamp: "09:00:02"
            ),
            TranscriptSegment(
                id: "other-after",
                meetingID: interleaved.id,
                text: "Wrong next meeting context.",
                timestamp: "09:00:03"
            ),
            TranscriptSegment(
                id: "relevant-after",
                meetingID: relevant.id,
                text: "After the match, the team approved the approach.",
                timestamp: "09:00:04"
            ),
        ])

        let evidence = try database.retrieveEvidence(
            question: "unique grounding signal",
            scope: AskScope(meetingIDs: [relevant.id])
        )
        let source = try #require(evidence.first)
        let prompt = LocalIntelligenceService.boundedSourceText(evidence)

        #expect(source.context.contains("MATCH —"))
        #expect(source.context.contains("unique grounding signal"))
        #expect(source.context.contains("Before long context"))
        #expect(source.context.contains("After the match"))
        #expect(!source.context.contains("Wrong previous"))
        #expect(!source.context.contains("Wrong next"))
        #expect(prompt.contains("unique grounding signal"))
    }

    @Test("Ask bounds questions, selected meetings, and result counts")
    func retrievalBounds() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let meeting = try database.createMeeting(title: "Bounded")
        try database.insertTranscripts(
            (1...20).map { index in
                TranscriptSegment(
                    id: "bounded-\(index)",
                    meetingID: meeting.id,
                    text: "Bounded evidence \(index)",
                    timestamp: "00:\(index)"
                )
            }
        )

        #expect(throws: DatabaseError.self) {
            try database.retrieveEvidence(
                question: String(repeating: "x", count: 1_001),
                scope: AskScope()
            )
        }
        #expect(throws: DatabaseError.self) {
            try database.retrieveEvidence(
                question: "bounded",
                scope: AskScope(meetingIDs: Set((1...101).map { "meeting-\($0)" }))
            )
        }
        let evidence = try database.retrieveEvidence(
            question: "bounded",
            scope: AskScope(meetingIDs: [meeting.id]),
            limit: 100
        )
        #expect(evidence.count == 12)
    }

    @Test("Deleting a meeting cascades through local records")
    func deletionCascade() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let meeting = try database.createMeeting(title: "Temporary")
        try database.insertTranscripts([
            TranscriptSegment(
                id: "temporary-segment",
                meetingID: meeting.id,
                text: "Temporary transcript",
                timestamp: "12:00:00",
                speaker: "Speaker 1"
            ),
        ])
        try database.saveSpeakerAlias(
            meetingID: meeting.id,
            originalLabel: "Speaker 1",
            alias: "Person"
        )
        try database.deleteMeeting(id: meeting.id)

        #expect(try database.fetchMeeting(id: meeting.id) == nil)
        #expect(try database.fetchTranscripts(meetingID: meeting.id).isEmpty)
        #expect(try database.fetchSpeakerAliases(meetingID: meeting.id).isEmpty)
    }

    @Test("Retranscription replaces old transcript rows")
    func replaceTranscripts() throws {
        let fixture = try DatabaseFixture()
        let database = fixture.database
        let meeting = try database.createMeeting(title: "Replace")
        try database.insertTranscripts([
            TranscriptSegment(
                id: "old",
                meetingID: meeting.id,
                text: "Old text",
                timestamp: "00:00",
                audioStartTime: 0
            ),
        ])

        try database.replaceTranscripts(
            meetingID: meeting.id,
            with: [
                TranscriptSegment(
                    id: "new",
                    meetingID: meeting.id,
                    text: "New text",
                    timestamp: "00:02",
                    audioStartTime: 2
                ),
            ]
        )

        let rows = try database.fetchTranscripts(meetingID: meeting.id)
        #expect(rows.map(\.id) == ["new"])
        #expect(rows.map(\.text) == ["New text"])
    }

    @Test("Cancelling Ask clears local evidence and ignores the pending operation")
    @MainActor
    func cancelAsk() throws {
        let fixture = try DatabaseFixture()
        let store = try AppStore(databaseURL: fixture.databaseURL)
        let meeting = try store.database.createMeeting(title: "Ask cancellation")
        try store.database.insertTranscripts([
            TranscriptSegment(
                id: "ask-cancel-segment",
                meetingID: meeting.id,
                text: "The release stays local.",
                timestamp: "00:01"
            ),
        ])

        store.retrieveAskEvidence(question: "Where does the release stay?", scope: .init())
        #expect(store.askPhase == .generating)
        #expect(!store.askEvidence.isEmpty)

        store.cancelAsk()

        #expect(store.askPhase == .idle)
        #expect(store.askEvidence.isEmpty)
        #expect(store.askAnswer == nil)
    }

    @Test("External confirmation uses the reviewed request and destination")
    @MainActor
    func externalAskConfirmationUsesReviewedSnapshot() async throws {
        let fixture = try DatabaseFixture()
        let answerer = CapturingAskAnswerer()
        var configuration = AIConfiguration(
            provider: .ollama,
            model: "fixture",
            endpoint: "https://first.invalid"
        )
        let store = try AppStore(
            databaseURL: fixture.databaseURL,
            askAnswerer: answerer,
            askConfiguration: { configuration }
        )
        let meeting = try store.database.createMeeting(title: "Confirmation")
        try store.database.insertTranscripts([
            TranscriptSegment(
                id: "alpha",
                meetingID: meeting.id,
                text: "Alpha evidence belongs to the reviewed request.",
                timestamp: "00:01"
            ),
            TranscriptSegment(
                id: "beta",
                meetingID: meeting.id,
                text: "Beta evidence belongs to a different request.",
                timestamp: "00:02"
            ),
        ])

        await store.answerQuestion(
            question: "alpha",
            scope: AskScope(meetingIDs: [meeting.id])
        )
        let reviewedEvidenceIDs = store.askEvidence.map(\.transcriptID)
        #expect(store.askPhase == .confirming("Ollama"))
        #expect(await answerer.capturedRequests().isEmpty)

        configuration.endpoint = "https://second.invalid"
        await store.confirmExternalAsk()

        let confirmed = try #require(await answerer.capturedRequests().first)
        #expect(confirmed.question == "alpha")
        #expect(confirmed.transcriptIDs == reviewedEvidenceIDs)
        #expect(confirmed.endpoint == "https://first.invalid")
        #expect(store.askPhase == .answered)

        await store.answerQuestion(
            question: "beta",
            scope: AskScope(meetingIDs: [meeting.id])
        )
        #expect(store.askPhase == .confirming("Ollama"))
        #expect(await answerer.capturedRequests().count == 1)
    }
}

private struct CapturedAskRequest: Sendable {
    let question: String
    let transcriptIDs: [String]
    let endpoint: String
}

private actor CapturingAskAnswerer: AskAnswering {
    private var requests: [CapturedAskRequest] = []

    func answer(
        question: String,
        evidence: [AskEvidence],
        configuration: AIConfiguration
    ) async throws -> AskAnswer {
        requests.append(
            CapturedAskRequest(
                question: question,
                transcriptIDs: evidence.map(\.transcriptID),
                endpoint: configuration.endpoint
            )
        )
        let fallback = LocalIntelligenceService.extractiveAnswer(evidence: evidence)
        return AskAnswer(
            claims: fallback.claims,
            citations: fallback.citations,
            provider: configuration.provider.title,
            model: configuration.model
        )
    }

    func capturedRequests() -> [CapturedAskRequest] {
        requests
    }
}

private final class DatabaseFixture {
    let directory: URL
    let database: SQLiteDatabase
    let databaseURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("notive-swift-tests-\(UUID().uuidString)", isDirectory: true)
        databaseURL = directory.appendingPathComponent("meeting_minutes.sqlite")
        database = try SQLiteDatabase(url: databaseURL)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }
}
