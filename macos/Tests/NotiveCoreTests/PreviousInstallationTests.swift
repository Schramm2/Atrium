import Foundation
import Testing
@testable import NotiveCore

@Suite("Earlier installation data")
struct PreviousInstallationTests {
    @Test("A survey reports what an earlier database holds")
    func surveyReportsCounts() throws {
        let previous = try InstallationFixture()
        let meeting = try previous.database.createMeeting(title: "Quarterly review")
        try previous.database.insertTranscripts([
            TranscriptSegment(
                id: "previous-1",
                meetingID: meeting.id,
                text: "We agreed to ship on Friday.",
                timestamp: "09:00:00"
            ),
        ])

        let survey = try #require(SQLiteDatabase.survey(at: previous.databaseURL))

        #expect(survey.meetingCount == 1)
        #expect(survey.transcriptCount == 1)
        #expect(survey.latestMeetingDate != nil)
    }

    @Test("An empty or missing database is not offered")
    func emptyDatabaseIsNotOffered() throws {
        let previous = try InstallationFixture()

        #expect(SQLiteDatabase.survey(at: previous.databaseURL) == nil)
        #expect(SQLiteDatabase.survey(at: previous.directory.appendingPathComponent("gone.sqlite")) == nil)
    }

    @Test("Restoring copies meetings, transcripts, notes, summaries, and aliases")
    func restoreCopiesEverythingAttachedToAMeeting() throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        let meeting = try previous.database.createMeeting(title: "Design review")
        try previous.database.insertTranscripts([
            TranscriptSegment(
                id: "previous-segment",
                meetingID: meeting.id,
                text: "The unique launch phrase is marigold.",
                timestamp: "09:00:00",
                audioStartTime: 12,
                speaker: "Speaker 1"
            ),
        ])
        try previous.database.saveNote(
            MeetingNote(meetingID: meeting.id, markdown: "Follow up with design.")
        )
        try previous.database.saveSummary(meetingID: meeting.id, markdown: "Shipped the review.")
        try previous.database.saveSpeakerAlias(
            meetingID: meeting.id,
            originalLabel: "Speaker 1",
            alias: "Thandi"
        )

        let summary = try PreviousInstallationService.restore(
            previous.installation,
            into: current.database,
            recordingsFolder: current.recordingsFolder
        )

        #expect(summary.importedMeetingCount == 1)
        #expect(summary.skippedMeetingCount == 0)
        #expect(try current.database.fetchMeetings().map(\.title) == ["Design review"])
        #expect(try current.database.fetchTranscripts(meetingID: meeting.id).count == 1)
        #expect(try current.database.fetchNote(meetingID: meeting.id)?.markdown == "Follow up with design.")
        #expect(try current.database.fetchSummary(meetingID: meeting.id)?.markdown == "Shipped the review.")
        #expect(try current.database.fetchSpeakerAliases(meetingID: meeting.id).first?.alias == "Thandi")
    }

    @Test("Restored transcripts are searchable")
    func restoredTranscriptsAreSearchable() throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        let meeting = try previous.database.createMeeting(title: "Search restore")
        try previous.database.insertTranscripts([
            TranscriptSegment(
                id: "previous-search",
                meetingID: meeting.id,
                text: "The unique launch phrase is marigold.",
                timestamp: "09:00:00"
            ),
        ])

        _ = try PreviousInstallationService.restore(
            previous.installation,
            into: current.database,
            recordingsFolder: current.recordingsFolder
        )

        #expect(try current.database.search("marigold").count == 1)
        #expect(
            try current.database.retrieveEvidence(
                question: "marigold",
                scope: AskScope()
            ).isEmpty == false
        )
    }

    @Test("Restoring twice adds nothing the second time")
    func restoringTwiceAddsNothing() throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        _ = try previous.database.createMeeting(title: "Repeat restore")

        _ = try PreviousInstallationService.restore(
            previous.installation,
            into: current.database,
            recordingsFolder: current.recordingsFolder
        )
        let second = try PreviousInstallationService.restore(
            previous.installation,
            into: current.database,
            recordingsFolder: current.recordingsFolder
        )

        #expect(second.importedMeetingCount == 0)
        #expect(second.skippedMeetingCount == 1)
        #expect(try current.database.fetchMeetings().count == 1)
    }

    @Test("A meeting held under a different identifier is left alone")
    func matchingTitleAndTimeIsSkipped() throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        let held = try current.database.createMeeting(title: "Standup")
        try current.database.insertTranscripts([
            TranscriptSegment(
                id: "held-segment",
                meetingID: held.id,
                text: "The current transcript.",
                timestamp: "09:00:00"
            ),
        ])
        let createdAt = try #require(
            current.database.fetchMeetings().first.map { DateCoding.encode($0.createdAt) }
        )
        try previous.insertMeeting(
            id: "meeting-earlier-copy",
            title: "Standup",
            createdAt: createdAt,
            transcript: "The earlier transcript."
        )

        let summary = try PreviousInstallationService.restore(
            previous.installation,
            into: current.database,
            recordingsFolder: current.recordingsFolder
        )

        #expect(summary.importedMeetingCount == 0)
        #expect(summary.skippedMeetingCount == 1)
        #expect(try current.database.fetchMeetings().count == 1)
        #expect(
            try current.database.fetchTranscripts(meetingID: held.id).map(\.text)
                == ["The current transcript."]
        )
    }

    @Test("A database written by an earlier release is read without its newer columns")
    func earlierSchemaIsRead() throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        try previous.runSQL(
            """
            CREATE TABLE meetings (
                id TEXT PRIMARY KEY, title TEXT NOT NULL,
                created_at TEXT NOT NULL, updated_at TEXT NOT NULL
            );
            CREATE TABLE transcripts (
                id TEXT PRIMARY KEY, meeting_id TEXT NOT NULL,
                transcript TEXT NOT NULL, timestamp TEXT NOT NULL
            );
            INSERT INTO meetings VALUES
                ('meeting-old', 'Kickoff', '2024-02-01T09:00:00.000Z', '2024-02-01T09:00:00.000Z');
            INSERT INTO transcripts VALUES
                ('old-segment', 'meeting-old', 'An early conversation.', '09:00:00');
            """
        )

        let summary = try PreviousInstallationService.restore(
            previous.installation,
            into: current.database,
            recordingsFolder: current.recordingsFolder
        )

        #expect(summary.importedMeetingCount == 1)
        #expect(try current.database.fetchMeetings().map(\.title) == ["Kickoff"])
        #expect(
            try current.database.fetchTranscripts(meetingID: "meeting-old").map(\.text)
                == ["An early conversation."]
        )
    }

    @Test("Recordings outside the recordings folder are brought into it")
    func recordingsAreBroughtIntoTheRecordingsFolder() throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        let outside = try previous.makeRecordingFolder(
            named: "Kickoff_2024-02-01_09-00",
            in: previous.directory.appendingPathComponent("old-recordings", isDirectory: true)
        )
        let inside = try previous.makeRecordingFolder(
            named: "Retro_2024-03-01_09-00",
            in: current.recordingsFolder
        )
        let moving = try previous.database.createMeeting(title: "Kickoff", folderPath: outside.path)
        let staying = try previous.database.createMeeting(title: "Retro", folderPath: inside.path)

        let summary = try PreviousInstallationService.restore(
            previous.installation,
            into: current.database,
            recordingsFolder: current.recordingsFolder
        )

        #expect(summary.copiedRecordingCount == 1)
        let movedPath = try #require(current.database.fetchMeeting(id: moving.id)?.folderPath)
        #expect(
            movedPath == current.recordingsFolder
                .appendingPathComponent("Kickoff_2024-02-01_09-00", isDirectory: true).path
        )
        #expect(
            FileManager.default.fileExists(
                atPath: URL(fileURLWithPath: movedPath)
                    .appendingPathComponent("audio.m4a").path
            )
        )
        #expect(FileManager.default.fileExists(atPath: outside.path))
        #expect(try current.database.fetchMeeting(id: staying.id)?.folderPath == inside.path)
    }

    @Test("A recording folder that no longer exists keeps its recorded path")
    func missingRecordingFolderKeepsItsPath() throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        let missing = previous.directory.appendingPathComponent("gone", isDirectory: true).path
        let meeting = try previous.database.createMeeting(title: "Lost audio", folderPath: missing)

        let summary = try PreviousInstallationService.restore(
            previous.installation,
            into: current.database,
            recordingsFolder: current.recordingsFolder
        )

        #expect(summary.copiedRecordingCount == 0)
        #expect(try current.database.fetchMeeting(id: meeting.id)?.folderPath == missing)
    }

    @Test("A failed restore stays available and reports the problem")
    @MainActor
    func failedRestoreRemainsAvailable() async throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        _ = try previous.database.createMeeting(title: "Unavailable restore")
        let installation = previous.installation
        try FileManager.default.removeItem(at: previous.databaseURL)
        let store = try AppStore(
            databaseURL: current.databaseURL,
            recordingsFolder: { current.recordingsFolder },
            previousInstallation: installation
        )

        let result = await store.restorePreviousInstallation()

        #expect(result == nil)
        #expect(store.previousInstallation == installation)
        #expect(store.previousInstallationRestoreError != nil)
    }

    @Test("A restore offer counts only meetings that are still missing")
    @MainActor
    func restoreOfferCountsOnlyMissingMeetings() throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        try previous.insertMeeting(
            id: "previous-held",
            title: "Held meeting",
            createdAt: "2024-02-01T09:00:00.000Z",
            transcript: "Already here."
        )
        try previous.insertMeeting(
            id: "previous-missing",
            title: "Missing meeting",
            createdAt: "2024-02-02T09:00:00.000Z",
            transcript: "Still to restore."
        )
        try current.insertMeeting(
            id: "current-held",
            title: "Held meeting",
            createdAt: "2024-02-01 09:00:00",
            transcript: "Already here."
        )

        let store = try AppStore(
            databaseURL: current.databaseURL,
            recordingsFolder: { current.recordingsFolder },
            previousInstallation: previous.installation
        )

        #expect(store.previousInstallation?.importableMeetingCount == 1)
    }

    @Test("A completed restore is not offered again after startup")
    @MainActor
    func completedRestoreIsNotOfferedAgain() async throws {
        let previous = try InstallationFixture()
        let current = try InstallationFixture()
        _ = try previous.database.createMeeting(title: "Already restored")
        let installation = previous.installation
        let store = try AppStore(
            databaseURL: current.databaseURL,
            recordingsFolder: { current.recordingsFolder },
            previousInstallation: installation
        )

        _ = await store.restorePreviousInstallation()
        let reopenedStore = try AppStore(
            databaseURL: current.databaseURL,
            recordingsFolder: { current.recordingsFolder },
            previousInstallation: installation
        )

        #expect(store.previousInstallation == nil)
        #expect(reopenedStore.previousInstallation == nil)
    }

    @Test("The database in use is never offered as an earlier installation")
    func theCurrentDatabaseIsNotOffered() throws {
        let current = try InstallationFixture()
        _ = try current.database.createMeeting(title: "In use")

        #expect(
            PreviousInstallationService.find(
                in: [current.databaseURL],
                currentDatabaseURL: current.databaseURL
            ) == nil
        )
        #expect(
            PreviousInstallationService.find(
                in: [current.databaseURL],
                currentDatabaseURL: nil
            )?.meetingCount == 1
        )
    }
}

private final class InstallationFixture {
    let directory: URL
    let databaseURL: URL
    let recordingsFolder: URL
    private var openedDatabase: SQLiteDatabase?

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("notive-restore-tests-\(UUID().uuidString)", isDirectory: true)
        databaseURL = directory.appendingPathComponent("meeting_minutes.sqlite")
        recordingsFolder = directory.appendingPathComponent("recordings", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    /// Opened on demand so a test can write an earlier schema before the current one is created.
    var database: SQLiteDatabase {
        get throws {
            if let openedDatabase { return openedDatabase }
            let database = try SQLiteDatabase(url: databaseURL)
            openedDatabase = database
            return database
        }
    }

    var installation: PreviousInstallation {
        PreviousInstallation(
            databaseURL: databaseURL,
            survey: SQLiteDatabase.survey(at: databaseURL)
                ?? MeetingDataSurvey(meetingCount: 0, transcriptCount: 0, latestMeetingDate: nil)
        )
    }

    func insertMeeting(
        id: String,
        title: String,
        createdAt: String,
        transcript: String
    ) throws {
        _ = try database
        try runSQL(
            """
            INSERT INTO meetings(id, title, created_at, updated_at)
                VALUES ('\(id)', '\(title)', '\(createdAt)', '\(createdAt)');
            INSERT INTO transcripts(id, meeting_id, transcript, timestamp)
                VALUES ('\(id)-segment', '\(id)', '\(transcript)', '09:00:00');
            """
        )
    }

    func makeRecordingFolder(named name: String, in parent: URL) throws -> URL {
        let folder = parent.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("audio".utf8).write(to: folder.appendingPathComponent("audio.m4a"))
        return folder
    }

    /// Writes SQL the current schema cannot express, such as an exact creation time.
    func runSQL(_ sql: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [databaseURL.path, sql]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw DatabaseError.step("sqlite3 exited with \(process.terminationStatus)")
        }
    }
}
