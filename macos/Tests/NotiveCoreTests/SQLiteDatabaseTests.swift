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
