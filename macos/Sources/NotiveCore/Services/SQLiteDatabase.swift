import CSQLite
import Foundation

public enum DatabaseError: LocalizedError, Equatable {
    case open(String)
    case prepare(String)
    case bind(String)
    case step(String)
    case invalidData(String)

    public var errorDescription: String? {
        switch self {
        case let .open(message), let .prepare(message), let .bind(message),
             let .step(message), let .invalidData(message):
            message
        }
    }
}

/// What another Notive database holds, read before anything is copied from it.
public struct MeetingDataSurvey: Equatable, Sendable {
    public let meetingCount: Int
    public let transcriptCount: Int
    public let latestMeetingDate: Date?

    public init(meetingCount: Int, transcriptCount: Int, latestMeetingDate: Date?) {
        self.meetingCount = meetingCount
        self.transcriptCount = transcriptCount
        self.latestMeetingDate = latestMeetingDate
    }
}

public struct MeetingImportResult: Equatable, Sendable {
    public let imported: [Meeting]
    public let skippedMeetingCount: Int

    public var importedMeetingCount: Int { imported.count }
}

public final class SQLiteDatabase: @unchecked Sendable {
    public static let applicationSupportDirectory = "Notive"
    public static let legacyApplicationSupportDirectory = "com.ubundi.meet"
    public static let databaseFilename = "meeting_minutes.sqlite"

    private let connection: OpaquePointer
    private let lock = NSRecursiveLock()

    public static func applicationSupportURL(
        fileManager: FileManager = .default
    ) throws -> URL {
        try supportURL(named: applicationSupportDirectory, create: true, fileManager: fileManager)
    }

    public static func defaultDatabaseURL(
        fileManager: FileManager = .default
    ) throws -> URL {
        try applicationSupportURL(fileManager: fileManager)
            .appendingPathComponent(databaseFilename)
    }

    /// Notive stored data under the bundle identifier before the `Notive` folder.
    public static func legacyApplicationSupportURL(
        fileManager: FileManager = .default
    ) throws -> URL {
        try supportURL(
            named: legacyApplicationSupportDirectory,
            create: false,
            fileManager: fileManager
        )
    }

    public static func legacyDatabaseURL(
        fileManager: FileManager = .default
    ) throws -> URL {
        try legacyApplicationSupportURL(fileManager: fileManager)
            .appendingPathComponent(databaseFilename)
    }

    private static func supportURL(
        named name: String,
        create: Bool,
        fileManager: FileManager
    ) throws -> URL {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: create
        )
        return support.appendingPathComponent(name, isDirectory: true)
    }

    public init(url: URL, createIfMissing: Bool = true) throws {
        if createIfMissing {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }

        var database: OpaquePointer?
        let flags = createIfMissing
            ? SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
            : SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &database, flags, nil) == SQLITE_OK,
              let database else {
            let message = database.map { String(cString: sqlite3_errmsg($0)) }
                ?? "SQLite did not return a connection."
            if let database { sqlite3_close(database) }
            throw DatabaseError.open("Could not open Notive database: \(message)")
        }
        connection = database

        do {
            try execute("PRAGMA foreign_keys = ON")
            sqlite3_busy_timeout(connection, 5_000)
            if createIfMissing {
                try initializeSchema()
            }
        } catch {
            sqlite3_close(database)
            throw error
        }
    }

    deinit {
        sqlite3_close(connection)
    }

    public func fetchMeetings(matching search: String = "") throws -> [Meeting] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return try query(
                """
                SELECT id, title, created_at, updated_at, folder_path
                FROM meetings
                ORDER BY created_at DESC
                """
            ) { statement in
                try self.meeting(from: statement)
            }
        }

        return try query(
            """
            SELECT DISTINCT m.id, m.title, m.created_at, m.updated_at, m.folder_path
            FROM meetings m
            LEFT JOIN transcripts t ON t.meeting_id = m.id
            WHERE m.title LIKE ? ESCAPE '\\' OR t.transcript LIKE ? ESCAPE '\\'
            ORDER BY m.created_at DESC
            """,
            values: [.text("%\(Self.escapeLike(trimmed))%"), .text("%\(Self.escapeLike(trimmed))%")]
        ) { statement in
            try self.meeting(from: statement)
        }
    }

    public func fetchMeeting(id: String) throws -> Meeting? {
        try query(
            """
            SELECT id, title, created_at, updated_at, folder_path
            FROM meetings WHERE id = ? LIMIT 1
            """,
            values: [.text(id)]
        ) { statement in
            try self.meeting(from: statement)
        }.first
    }

    public func createMeeting(title: String, folderPath: String? = nil) throws -> Meeting {
        let now = Date()
        let meeting = Meeting(
            id: "meeting-\(UUID().uuidString.lowercased())",
            title: title,
            createdAt: now,
            updatedAt: now,
            folderPath: folderPath
        )
        try execute(
            """
            INSERT INTO meetings(id, title, created_at, updated_at, folder_path)
            VALUES (?, ?, ?, ?, ?)
            """,
            values: [
                .text(meeting.id),
                .text(meeting.title),
                .text(DateCoding.encode(now)),
                .text(DateCoding.encode(now)),
                folderPath.map(Value.text) ?? .null,
            ]
        )
        return meeting
    }

    public func updateMeetingTitle(id: String, title: String) throws {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw DatabaseError.invalidData("A meeting title cannot be empty.")
        }
        try execute(
            "UPDATE meetings SET title = ?, updated_at = ? WHERE id = ?",
            values: [.text(cleaned), .text(DateCoding.encode(.now)), .text(id)]
        )
    }

    public func deleteMeeting(id: String) throws {
        try execute("DELETE FROM meetings WHERE id = ?", values: [.text(id)])
    }

    public func updateMeetingFolderPath(id: String, folderPath: String?) throws {
        try execute(
            "UPDATE meetings SET folder_path = ? WHERE id = ?",
            values: [folderPath.map(Value.text) ?? .null, .text(id)]
        )
    }

    // MARK: - Earlier meeting data

    /// Counts the meeting data in another Notive database without changing it.
    ///
    /// Returns `nil` when the file is missing, is not a Notive database, or holds no meetings.
    public static func survey(at url: URL) -> MeetingDataSurvey? {
        guard FileManager.default.fileExists(atPath: url.path),
              let database = try? SQLiteDatabase(url: url, createIfMissing: false),
              database.hasTable("meetings", schema: "main") else {
            return nil
        }
        let meetingCount = database.count("SELECT COUNT(*) FROM main.meetings")
        guard meetingCount > 0 else { return nil }
        let transcriptCount = database.hasTable("transcripts", schema: "main")
            ? database.count("SELECT COUNT(*) FROM main.transcripts")
            : 0
        let latest = (try? database.query("SELECT MAX(created_at) FROM main.meetings") {
            database.optionalText($0, 0)
        })?.first ?? nil
        return MeetingDataSurvey(
            meetingCount: meetingCount,
            transcriptCount: transcriptCount,
            latestMeetingDate: latest.map(DateCoding.decode)
        )
    }

    /// Copies meetings that this database does not hold yet from another Notive database.
    ///
    /// A meeting is already held when its identifier matches, or when both its title and its
    /// creation time match. Held meetings and everything attached to them stay unchanged.
    @discardableResult
    public func importMeetings(from sourceURL: URL) throws -> MeetingImportResult {
        lock.lock()
        defer { lock.unlock() }

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw DatabaseError.invalidData("There is no Notive database at \(sourceURL.path).")
        }
        try execute("ATTACH DATABASE ? AS previous", values: [.text(sourceURL.path)])
        defer { try? execute("DETACH DATABASE previous") }

        guard hasTable("meetings", schema: "previous") else {
            throw DatabaseError.invalidData("That file is not a Notive meeting database.")
        }

        let sourceColumns = Set(columns(of: "meetings", schema: "previous"))
        guard ["id", "title", "created_at", "updated_at"].allSatisfy(sourceColumns.contains) else {
            throw DatabaseError.invalidData("That file is not a Notive meeting database.")
        }
        let folderPathColumn = sourceColumns.contains("folder_path") ? "folder_path" : "NULL"
        let candidates = try query(
            """
            SELECT id, title, created_at, updated_at, \(folderPathColumn)
            FROM previous.meetings ORDER BY created_at
            """
        ) { statement in
            SourceMeeting(
                id: self.text(statement, 0),
                title: self.text(statement, 1),
                createdAt: self.text(statement, 2),
                updatedAt: self.text(statement, 3),
                folderPath: self.optionalText(statement, 4)
            )
        }

        let heldIDs = Set(try query("SELECT id FROM main.meetings") { self.text($0, 0) })
        let heldTitleAndTime = Set(
            try query("SELECT title, created_at FROM main.meetings") { statement in
                SourceMeeting.titleAndTimeKey(self.text(statement, 0), self.text(statement, 1))
            }
        )
        let arriving = candidates.filter { candidate in
            !heldIDs.contains(candidate.id)
                && !heldTitleAndTime.contains(candidate.titleAndTimeKey)
        }
        guard !arriving.isEmpty else {
            return MeetingImportResult(
                imported: [],
                skippedMeetingCount: candidates.count
            )
        }

        try transaction {
            try execute("CREATE TEMP TABLE IF NOT EXISTS arriving_meetings(id TEXT PRIMARY KEY)")
            try execute("DELETE FROM arriving_meetings")
            for meeting in arriving {
                try execute(
                    "INSERT INTO arriving_meetings(id) VALUES (?)",
                    values: [.text(meeting.id)]
                )
                try execute(
                    """
                    INSERT INTO main.meetings(id, title, created_at, updated_at, folder_path)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    values: [
                        .text(meeting.id),
                        .text(meeting.title),
                        .text(meeting.createdAt),
                        .text(meeting.updatedAt),
                        meeting.folderPath.map(Value.text) ?? .null,
                    ]
                )
            }
            for table in Self.attachedTables {
                try copyArrivingRows(table: table)
            }
            try execute("DROP TABLE arriving_meetings")
        }

        return MeetingImportResult(
            imported: arriving.map(\.meeting),
            skippedMeetingCount: candidates.count - arriving.count
        )
    }

    /// Reports whether another Notive database holds a meeting this database does not hold yet.
    ///
    /// A meeting is held when its identifier matches, or when both its title and creation time
    /// match. This uses the same rule as `importMeetings(from:)` without changing either database.
    public func hasImportableMeetings(from sourceURL: URL) throws -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw DatabaseError.invalidData("There is no Notive database at \(sourceURL.path).")
        }
        try execute("ATTACH DATABASE ? AS previous", values: [.text(sourceURL.path)])
        defer { try? execute("DETACH DATABASE previous") }

        guard hasTable("meetings", schema: "previous") else {
            throw DatabaseError.invalidData("That file is not a Notive meeting database.")
        }
        let sourceColumns = Set(columns(of: "meetings", schema: "previous"))
        guard ["id", "title", "created_at", "updated_at"].allSatisfy(sourceColumns.contains) else {
            throw DatabaseError.invalidData("That file is not a Notive meeting database.")
        }
        let candidates = try query(
            "SELECT id, title, created_at FROM previous.meetings"
        ) { statement in
            SourceMeeting(
                id: self.text(statement, 0),
                title: self.text(statement, 1),
                createdAt: self.text(statement, 2),
                updatedAt: "",
                folderPath: nil
            )
        }
        let heldIDs = Set(try query("SELECT id FROM main.meetings") { self.text($0, 0) })
        let heldTitleAndTime = Set(
            try query("SELECT title, created_at FROM main.meetings") { statement in
                SourceMeeting.titleAndTimeKey(self.text(statement, 0), self.text(statement, 1))
            }
        )
        return candidates.contains { candidate in
            !heldIDs.contains(candidate.id)
                && !heldTitleAndTime.contains(candidate.titleAndTimeKey)
        }
    }

    /// The tables carried across with each meeting, and the columns each one may hold.
    ///
    /// A database written by an earlier Notive release can be missing a table or a column, so
    /// only the columns present in both databases are copied.
    private static let attachedTables: [AttachedTable] = [
        AttachedTable(
            name: "transcripts",
            required: ["id", "meeting_id", "transcript", "timestamp"],
            optional: [
                "summary", "action_items", "key_points",
                "audio_start_time", "audio_end_time", "duration", "speaker",
            ]
        ),
        AttachedTable(
            name: "meeting_notes",
            required: ["meeting_id", "created_at", "updated_at"],
            optional: ["notes_markdown", "notes_json"]
        ),
        AttachedTable(
            name: "summary_processes",
            required: ["meeting_id", "status", "created_at", "updated_at"],
            optional: [
                "error", "result", "start_time", "end_time", "chunk_count",
                "processing_time", "metadata", "result_backup", "result_backup_timestamp",
            ]
        ),
        AttachedTable(
            name: "speaker_aliases",
            required: ["meeting_id", "original_speaker_label", "alias"],
            optional: ["created_at", "updated_at"]
        ),
    ]

    private struct AttachedTable {
        let name: String
        let required: [String]
        let optional: [String]
    }

    private struct SourceMeeting {
        let id: String
        let title: String
        let createdAt: String
        let updatedAt: String
        let folderPath: String?

        var titleAndTimeKey: String { Self.titleAndTimeKey(title, createdAt) }

        var meeting: Meeting {
            Meeting(
                id: id,
                title: title,
                createdAt: DateCoding.decode(createdAt),
                updatedAt: DateCoding.decode(updatedAt),
                folderPath: folderPath
            )
        }

        static func titleAndTimeKey(_ title: String, _ createdAt: String) -> String {
            "\(title)\u{1}\(createdAt)"
        }
    }

    private func copyArrivingRows(table: AttachedTable) throws {
        guard hasTable(table.name, schema: "previous") else { return }
        let present = Set(columns(of: table.name, schema: "previous"))
        guard table.required.allSatisfy(present.contains) else { return }
        let columns = table.required + table.optional.filter(present.contains)
        let columnList = columns.joined(separator: ", ")
        let sourceList = columns.map { "source.\($0)" }.joined(separator: ", ")
        try execute(
            """
            INSERT OR IGNORE INTO main.\(table.name)(\(columnList))
            SELECT \(sourceList) FROM previous.\(table.name) source
            JOIN arriving_meetings arriving ON arriving.id = source.meeting_id
            """
        )
    }

    private func hasTable(_ name: String, schema: String) -> Bool {
        let rows = try? query(
            "SELECT name FROM \(schema).sqlite_master WHERE type = 'table' AND name = ?",
            values: [.text(name)]
        ) { self.text($0, 0) }
        return rows?.isEmpty == false
    }

    private func columns(of table: String, schema: String) -> [String] {
        (try? query("PRAGMA \(schema).table_info(\(table))") { self.text($0, 1) }) ?? []
    }

    private func count(_ sql: String) -> Int {
        let rows = try? query(sql) { Int(self.optionalDouble($0, 0) ?? 0) }
        return rows?.first ?? 0
    }

    public func fetchTranscripts(meetingID: String) throws -> [TranscriptSegment] {
        try query(
            """
            SELECT t.id, t.meeting_id, t.transcript, t.timestamp,
                   t.audio_start_time, t.audio_end_time, t.duration, t.speaker,
                   a.alias
            FROM transcripts t
            LEFT JOIN speaker_aliases a
              ON a.meeting_id = t.meeting_id
             AND a.original_speaker_label = t.speaker
            WHERE t.meeting_id = ?
            ORDER BY COALESCE(t.audio_start_time, 9223372036854775807), t.timestamp, t.rowid
            """,
            values: [.text(meetingID)]
        ) { statement in
            TranscriptSegment(
                id: self.text(statement, 0),
                meetingID: self.text(statement, 1),
                text: self.text(statement, 2),
                timestamp: self.text(statement, 3),
                audioStartTime: self.optionalDouble(statement, 4),
                audioEndTime: self.optionalDouble(statement, 5),
                duration: self.optionalDouble(statement, 6),
                speaker: self.optionalText(statement, 7),
                speakerDisplayName: self.optionalText(statement, 8)
            )
        }
    }

    public func insertTranscripts(_ segments: [TranscriptSegment]) throws {
        guard !segments.isEmpty else { return }
        try transaction {
            for segment in segments {
                try execute(
                    """
                    INSERT OR REPLACE INTO transcripts(
                        id, meeting_id, transcript, timestamp,
                        audio_start_time, audio_end_time, duration, speaker
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    values: [
                        .text(segment.id),
                        .text(segment.meetingID),
                        .text(segment.text),
                        .text(segment.timestamp),
                        segment.audioStartTime.map(Value.double) ?? .null,
                        segment.audioEndTime.map(Value.double) ?? .null,
                        segment.duration.map(Value.double) ?? .null,
                        segment.speaker.map(Value.text) ?? .null,
                    ]
                )
            }
        }
    }

    public func replaceTranscripts(meetingID: String, with segments: [TranscriptSegment]) throws {
        try transaction {
            try execute("DELETE FROM transcripts WHERE meeting_id = ?", values: [.text(meetingID)])
            for segment in segments {
                try execute(
                    """
                    INSERT INTO transcripts(
                        id, meeting_id, transcript, timestamp,
                        audio_start_time, audio_end_time, duration, speaker
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    values: [
                        .text(segment.id),
                        .text(segment.meetingID),
                        .text(segment.text),
                        .text(segment.timestamp),
                        segment.audioStartTime.map(Value.double) ?? .null,
                        segment.audioEndTime.map(Value.double) ?? .null,
                        segment.duration.map(Value.double) ?? .null,
                        segment.speaker.map(Value.text) ?? .null,
                    ]
                )
            }
        }
    }

    public func fetchNote(meetingID: String) throws -> MeetingNote? {
        try query(
            """
            SELECT meeting_id, notes_markdown, notes_json, created_at, updated_at
            FROM meeting_notes WHERE meeting_id = ? LIMIT 1
            """,
            values: [.text(meetingID)]
        ) { statement in
            MeetingNote(
                meetingID: self.text(statement, 0),
                markdown: self.optionalText(statement, 1) ?? "",
                json: self.optionalText(statement, 2),
                createdAt: DateCoding.decode(self.optionalText(statement, 3)),
                updatedAt: DateCoding.decode(self.optionalText(statement, 4))
            )
        }.first
    }

    public func saveNote(_ note: MeetingNote) throws {
        let now = Date()
        try execute(
            """
            INSERT INTO meeting_notes(
                meeting_id, notes_markdown, notes_json, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(meeting_id) DO UPDATE SET
                notes_markdown = excluded.notes_markdown,
                notes_json = excluded.notes_json,
                updated_at = excluded.updated_at
            """,
            values: [
                .text(note.meetingID),
                .text(note.markdown),
                note.json.map(Value.text) ?? .null,
                .text(DateCoding.encode(note.createdAt)),
                .text(DateCoding.encode(now)),
            ]
        )
    }

    public func fetchSpeakerAliases(meetingID: String) throws -> [SpeakerAlias] {
        try query(
            """
            SELECT meeting_id, original_speaker_label, alias, created_at, updated_at
            FROM speaker_aliases WHERE meeting_id = ?
            ORDER BY original_speaker_label COLLATE NOCASE
            """,
            values: [.text(meetingID)]
        ) { statement in
            SpeakerAlias(
                meetingID: self.text(statement, 0),
                originalLabel: self.text(statement, 1),
                alias: self.text(statement, 2),
                createdAt: DateCoding.decode(self.optionalText(statement, 3)),
                updatedAt: DateCoding.decode(self.optionalText(statement, 4))
            )
        }
    }

    public func saveSpeakerAlias(
        meetingID: String,
        originalLabel: String,
        alias: String
    ) throws {
        let cleaned = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw DatabaseError.invalidData("A speaker name cannot be empty.")
        }
        let now = DateCoding.encode(.now)
        try execute(
            """
            INSERT INTO speaker_aliases(
                meeting_id, original_speaker_label, alias, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(meeting_id, original_speaker_label) DO UPDATE SET
                alias = excluded.alias,
                updated_at = excluded.updated_at
            """,
            values: [.text(meetingID), .text(originalLabel), .text(cleaned), .text(now), .text(now)]
        )
    }

    public func clearSpeakerAlias(meetingID: String, originalLabel: String) throws {
        try execute(
            "DELETE FROM speaker_aliases WHERE meeting_id = ? AND original_speaker_label = ?",
            values: [.text(meetingID), .text(originalLabel)]
        )
    }

    public func fetchSummary(meetingID: String) throws -> MeetingSummary? {
        try query(
            """
            SELECT status, result, error
            FROM summary_processes WHERE meeting_id = ? LIMIT 1
            """,
            values: [.text(meetingID)]
        ) { statement in
            let rawJSON = self.optionalText(statement, 1) ?? ""
            return MeetingSummary(
                meetingID: meetingID,
                status: self.text(statement, 0),
                markdown: Self.extractMarkdown(from: rawJSON),
                rawJSON: rawJSON,
                error: self.optionalText(statement, 2)
            )
        }.first
    }

    public func saveSummary(meetingID: String, markdown: String) throws {
        let now = DateCoding.encode(.now)
        let object = ["markdown": markdown]
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        guard let rawJSON = String(data: data, encoding: .utf8) else {
            throw DatabaseError.invalidData("Could not encode the meeting summary.")
        }
        try execute(
            """
            INSERT INTO summary_processes(
                meeting_id, status, created_at, updated_at, result, chunk_count, processing_time
            ) VALUES (?, 'completed', ?, ?, ?, 0, 0.0)
            ON CONFLICT(meeting_id) DO UPDATE SET
                status = 'completed',
                updated_at = excluded.updated_at,
                result = excluded.result,
                error = NULL
            """,
            values: [.text(meetingID), .text(now), .text(now), .text(rawJSON)]
        )
    }

    public func search(_ search: String, limit: Int = 50) throws -> [TranscriptSearchResult] {
        let queryText = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !queryText.isEmpty else { return [] }
        let like = "%\(Self.escapeLike(queryText))%"
        return try query(
            """
            SELECT t.id, t.meeting_id, m.title, t.transcript, t.timestamp, t.audio_start_time
            FROM transcripts t
            JOIN meetings m ON m.id = t.meeting_id
            WHERE m.title LIKE ? ESCAPE '\\' OR t.transcript LIKE ? ESCAPE '\\'
            ORDER BY m.created_at DESC, t.audio_start_time
            LIMIT ?
            """,
            values: [.text(like), .text(like), .integer(Int64(limit))]
        ) { statement in
            TranscriptSearchResult(
                id: self.text(statement, 0),
                meetingID: self.text(statement, 1),
                meetingTitle: self.text(statement, 2),
                context: self.text(statement, 3),
                timestamp: self.text(statement, 4),
                audioStartTime: self.optionalDouble(statement, 5)
            )
        }
    }

    public func retrieveEvidence(
        question: String,
        scope: AskScope,
        limit: Int = 12
    ) throws -> [AskEvidence] {
        guard limit > 0 else { return [] }
        let cleanedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedQuestion.count <= 1_000 else {
            throw DatabaseError.invalidData("Ask questions must use 1,000 characters or fewer.")
        }
        guard scope.meetingIDs.count <= 100 else {
            throw DatabaseError.invalidData("Ask can search 100 selected meetings or fewer.")
        }
        let resultLimit = min(limit, 12)
        let terms = Self.searchTerms(from: cleanedQuestion)
        guard !terms.isEmpty || !scope.meetingIDs.isEmpty else { return [] }

        let meetingScope = try resolvedMeetingScope(for: terms, scope: scope)
        let effectiveMeetingIDs = meetingScope.meetingIDs
        let retrievalTerms = terms.filter { !meetingScope.matchedTitleTerms.contains($0) }
        if retrievalTerms.isEmpty, !effectiveMeetingIDs.isEmpty {
            return try representativeEvidence(
                meetingIDs: effectiveMeetingIDs,
                scope: scope,
                limit: resultLimit
            )
        }
        guard !retrievalTerms.isEmpty else { return [] }

        var filters: [String] = []
        var values: [Value] = [.text(retrievalTerms.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: " OR "))]

        if !effectiveMeetingIDs.isEmpty {
            filters.append("m.id IN (\(Array(repeating: "?", count: effectiveMeetingIDs.count).joined(separator: ", ")))")
            values.append(contentsOf: effectiveMeetingIDs.map(Value.text))
        }
        if let dateFrom = scope.dateFrom {
            filters.append("datetime(m.created_at) >= datetime(?)")
            values.append(.text(DateCoding.encode(dateFrom)))
        }
        if let dateTo = scope.dateTo {
            filters.append("datetime(m.created_at) <= datetime(?)")
            values.append(.text(DateCoding.encode(dateTo)))
        }
        values.append(.integer(Int64(max(resultLimit, 48))))

        let filterSQL = filters.isEmpty ? "" : " AND \(filters.joined(separator: " AND "))"
        let sql = """
            SELECT t.id, t.meeting_id, m.title, t.transcript, t.timestamp,
                   t.audio_start_time, COALESCE(a.alias, t.speaker), m.created_at,
                   bm25(transcripts_fts) AS rank
            FROM transcripts_fts
            JOIN transcripts t ON t.rowid = transcripts_fts.rowid
            JOIN meetings m ON m.id = t.meeting_id
            LEFT JOIN speaker_aliases a
              ON a.meeting_id = t.meeting_id AND a.original_speaker_label = t.speaker
            WHERE transcripts_fts MATCH ?\(filterSQL)
            ORDER BY rank, m.created_at DESC
            LIMIT ?
            """

        let rows = try query(sql, values: values) { statement in
            (
                transcriptID: self.text(statement, 0),
                meetingID: self.text(statement, 1),
                meetingTitle: self.text(statement, 2),
                snippet: self.text(statement, 3),
                timestamp: self.text(statement, 4),
                audioStartTime: self.optionalDouble(statement, 5),
                speaker: self.optionalText(statement, 6),
                createdAt: DateCoding.decode(self.optionalText(statement, 7)),
                rank: self.optionalDouble(statement, 8) ?? 0
            )
        }

        let perMeetingLimit = effectiveMeetingIDs.count == 1 ? resultLimit : min(resultLimit, 3)
        var meetingCounts: [String: Int] = [:]
        let selected = rows.filter { row in
            let count = meetingCounts[row.meetingID, default: 0]
            guard count < perMeetingLimit else { return false }
            meetingCounts[row.meetingID] = count + 1
            return true
        }.prefix(resultLimit)

        return try selected.enumerated().map { index, row in
            let context = try neighboringContext(
                meetingID: row.meetingID,
                transcriptID: row.transcriptID,
                fallback: row.snippet,
                speaker: row.speaker
            )
            return AskEvidence(
                id: "S\(index + 1)",
                meetingID: row.meetingID,
                meetingTitle: row.meetingTitle,
                transcriptID: row.transcriptID,
                snippet: row.snippet,
                context: context,
                speaker: row.speaker,
                timestamp: row.timestamp,
                audioStartTime: row.audioStartTime,
                meetingCreatedAt: row.createdAt,
                score: -row.rank
            )
        }
    }

    private func resolvedMeetingScope(
        for terms: [String],
        scope: AskScope
    ) throws -> ResolvedAskMeetingScope {
        if !scope.meetingIDs.isEmpty {
            return ResolvedAskMeetingScope(
                meetingIDs: scope.meetingIDs.sorted(),
                matchedTitleTerms: []
            )
        }

        let titleTerms = terms.filter { $0.count >= 4 }
        guard !titleTerms.isEmpty else { return .empty }

        var filters: [String] = []
        var values: [Value] = []
        if let dateFrom = scope.dateFrom {
            filters.append("datetime(created_at) >= datetime(?)")
            values.append(.text(DateCoding.encode(dateFrom)))
        }
        if let dateTo = scope.dateTo {
            filters.append("datetime(created_at) <= datetime(?)")
            values.append(.text(DateCoding.encode(dateTo)))
        }
        let filterSQL = filters.isEmpty ? "" : " WHERE \(filters.joined(separator: " AND "))"
        let meetings = try query(
            "SELECT id, title FROM meetings\(filterSQL)",
            values: values
        ) { statement in
            (id: self.text(statement, 0), title: self.text(statement, 1).lowercased())
        }
        let scored = meetings.map { meeting in
            (
                id: meeting.id,
                title: meeting.title,
                score: titleTerms.count { meeting.title.contains($0) }
            )
        }
        let bestScore = scored.map(\.score).max() ?? 0
        guard bestScore > 0 else { return .empty }
        let bestMatches = scored.filter { $0.score == bestScore }
        let matchedTitleTerms = titleTerms.filter { term in
            bestMatches.contains { $0.title.contains(term) }
        }
        var hasTitleOnlyTerm = false
        for term in matchedTitleTerms where try !transcriptsContain(term: term) {
            hasTitleOnlyTerm = true
            break
        }
        guard hasTitleOnlyTerm else { return .empty }
        return ResolvedAskMeetingScope(
            meetingIDs: bestMatches.map(\.id).sorted(),
            matchedTitleTerms: Set(matchedTitleTerms)
        )
    }

    private func representativeEvidence(
        meetingIDs: [String],
        scope: AskScope,
        limit: Int
    ) throws -> [AskEvidence] {
        var filters = [
            "m.id IN (\(Array(repeating: "?", count: meetingIDs.count).joined(separator: ", ")))"
        ]
        var values = meetingIDs.map(Value.text)
        if let dateFrom = scope.dateFrom {
            filters.append("datetime(m.created_at) >= datetime(?)")
            values.append(.text(DateCoding.encode(dateFrom)))
        }
        if let dateTo = scope.dateTo {
            filters.append("datetime(m.created_at) <= datetime(?)")
            values.append(.text(DateCoding.encode(dateTo)))
        }
        values.append(.integer(2_000))

        let rows = try query(
            """
            SELECT t.id, t.meeting_id, m.title, t.transcript, t.timestamp,
                   t.audio_start_time, COALESCE(a.alias, t.speaker), m.created_at
            FROM transcripts t
            JOIN meetings m ON m.id = t.meeting_id
            LEFT JOIN speaker_aliases a
              ON a.meeting_id = t.meeting_id AND a.original_speaker_label = t.speaker
            WHERE \(filters.joined(separator: " AND "))
            ORDER BY m.created_at DESC, COALESCE(t.audio_start_time, t.rowid), t.rowid
            LIMIT ?
            """,
            values: values
        ) { statement in
            (
                transcriptID: self.text(statement, 0),
                meetingID: self.text(statement, 1),
                meetingTitle: self.text(statement, 2),
                snippet: self.text(statement, 3),
                timestamp: self.text(statement, 4),
                audioStartTime: self.optionalDouble(statement, 5),
                speaker: self.optionalText(statement, 6),
                createdAt: DateCoding.decode(self.optionalText(statement, 7))
            )
        }

        let meetingOrder = rows.map(\.meetingID).uniqued()
        let perMeetingLimit = meetingOrder.count == 1 ? limit : min(limit, 3)
        var selected = Array(rows.prefix(0))
        for meetingID in meetingOrder {
            let allMeetingRows = rows.filter { $0.meetingID == meetingID }
            let substantiveRows = allMeetingRows.filter {
                $0.snippet.trimmingCharacters(in: .whitespacesAndNewlines).count >= 40
            }
            let meetingRows = substantiveRows.count >= min(3, allMeetingRows.count)
                ? substantiveRows
                : allMeetingRows
            let count = min(perMeetingLimit, meetingRows.count)
            guard count > 0 else { continue }
            if count == 1 {
                selected.append(meetingRows[0])
            } else {
                for index in 0..<count {
                    let position = Int(
                        (Double(index) * Double(meetingRows.count - 1) / Double(count - 1)).rounded()
                    )
                    selected.append(meetingRows[position])
                }
            }
        }

        return try selected.prefix(limit).enumerated().map { index, row in
            AskEvidence(
                id: "S\(index + 1)",
                meetingID: row.meetingID,
                meetingTitle: row.meetingTitle,
                transcriptID: row.transcriptID,
                snippet: row.snippet,
                context: try neighboringContext(
                    meetingID: row.meetingID,
                    transcriptID: row.transcriptID,
                    fallback: row.snippet,
                    speaker: row.speaker
                ),
                speaker: row.speaker,
                timestamp: row.timestamp,
                audioStartTime: row.audioStartTime,
                meetingCreatedAt: row.createdAt,
                score: 0
            )
        }
    }

    private func transcriptsContain(term: String) throws -> Bool {
        let quoted = "\"\(term.replacingOccurrences(of: "\"", with: "\"\""))\""
        return try query(
            "SELECT EXISTS(SELECT 1 FROM transcripts_fts WHERE transcripts_fts MATCH ? LIMIT 1)",
            values: [.text(quoted)]
        ) { statement in
            sqlite3_column_int(statement, 0) != 0
        }.first ?? false
    }

    private func neighboringContext(
        meetingID: String,
        transcriptID: String,
        fallback: String,
        speaker: String?
    ) throws -> String {
        let previous = try neighboringTranscript(
            meetingID: meetingID,
            transcriptID: transcriptID,
            before: true
        )
        let next = try neighboringTranscript(
            meetingID: meetingID,
            transcriptID: transcriptID,
            before: false
        )
        var parts: [String] = []
        if let previous {
            parts.append(
                "\(previous.speaker ?? "Speaker"): \(Self.boundedTranscript(previous.text, limit: 350))"
            )
        }
        parts.append(
            "MATCH — \(speaker ?? "Speaker"): \(Self.boundedTranscript(fallback, limit: 700))"
        )
        if let next {
            parts.append(
                "\(next.speaker ?? "Speaker"): \(Self.boundedTranscript(next.text, limit: 350))"
            )
        }
        return parts.joined(separator: "\n")
    }

    private func neighboringTranscript(
        meetingID: String,
        transcriptID: String,
        before: Bool
    ) throws -> (text: String, speaker: String?)? {
        let comparison = before ? "<" : ">"
        let order = before ? "DESC" : "ASC"
        return try query(
            """
            SELECT t.transcript, COALESCE(a.alias, t.speaker)
            FROM transcripts t
            LEFT JOIN speaker_aliases a
              ON a.meeting_id = t.meeting_id AND a.original_speaker_label = t.speaker
            WHERE t.meeting_id = ?
              AND t.rowid \(comparison) (
                  SELECT rowid FROM transcripts WHERE id = ? AND meeting_id = ?
              )
            ORDER BY t.rowid \(order)
            LIMIT 1
            """,
            values: [.text(meetingID), .text(transcriptID), .text(meetingID)]
        ) { statement in
            (text: self.text(statement, 0), speaker: self.optionalText(statement, 1))
        }.first
    }

    private static func boundedTranscript(_ value: String, limit: Int) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)) + "…"
    }

    private func initializeSchema() throws {
        try transaction {
            try execute(
                """
                CREATE TABLE IF NOT EXISTS meetings (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    folder_path TEXT
                )
                """
            )
            try execute(
                """
                CREATE TABLE IF NOT EXISTS transcripts (
                    id TEXT PRIMARY KEY,
                    meeting_id TEXT NOT NULL,
                    transcript TEXT NOT NULL,
                    timestamp TEXT NOT NULL,
                    summary TEXT,
                    action_items TEXT,
                    key_points TEXT,
                    audio_start_time REAL,
                    audio_end_time REAL,
                    duration REAL,
                    speaker TEXT,
                    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE
                )
                """
            )
            try execute(
                """
                CREATE TABLE IF NOT EXISTS summary_processes (
                    meeting_id TEXT PRIMARY KEY,
                    status TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    error TEXT,
                    result TEXT,
                    start_time TEXT,
                    end_time TEXT,
                    chunk_count INTEGER DEFAULT 0,
                    processing_time REAL DEFAULT 0.0,
                    metadata TEXT,
                    result_backup TEXT,
                    result_backup_timestamp TEXT,
                    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE
                )
                """
            )
            try execute(
                """
                CREATE TABLE IF NOT EXISTS meeting_notes (
                    meeting_id TEXT PRIMARY KEY NOT NULL,
                    notes_markdown TEXT,
                    notes_json TEXT,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE
                )
                """
            )
            try execute(
                """
                CREATE TABLE IF NOT EXISTS speaker_aliases (
                    meeting_id TEXT NOT NULL,
                    original_speaker_label TEXT NOT NULL,
                    alias TEXT NOT NULL,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (meeting_id, original_speaker_label),
                    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE
                )
                """
            )
            try execute(
                """
                CREATE UNIQUE INDEX IF NOT EXISTS idx_speaker_aliases_meeting_alias_nocase
                ON speaker_aliases(meeting_id, alias COLLATE NOCASE)
                """
            )
            try execute(
                """
                CREATE VIRTUAL TABLE IF NOT EXISTS transcripts_fts USING fts5(
                    transcript,
                    content='transcripts',
                    content_rowid='rowid',
                    tokenize='unicode61 remove_diacritics 2'
                )
                """
            )
            try execute(
                """
                CREATE TRIGGER IF NOT EXISTS transcripts_fts_insert AFTER INSERT ON transcripts BEGIN
                    INSERT INTO transcripts_fts(rowid, transcript) VALUES (new.rowid, new.transcript);
                END
                """
            )
            try execute(
                """
                CREATE TRIGGER IF NOT EXISTS transcripts_fts_delete AFTER DELETE ON transcripts BEGIN
                    INSERT INTO transcripts_fts(transcripts_fts, rowid, transcript)
                    VALUES ('delete', old.rowid, old.transcript);
                END
                """
            )
            try execute(
                """
                CREATE TRIGGER IF NOT EXISTS transcripts_fts_update AFTER UPDATE OF transcript ON transcripts BEGIN
                    INSERT INTO transcripts_fts(transcripts_fts, rowid, transcript)
                    VALUES ('delete', old.rowid, old.transcript);
                    INSERT INTO transcripts_fts(rowid, transcript) VALUES (new.rowid, new.transcript);
                END
                """
            )
        }
    }

    private func meeting(from statement: OpaquePointer) throws -> Meeting {
        Meeting(
            id: text(statement, 0),
            title: text(statement, 1),
            createdAt: DateCoding.decode(optionalText(statement, 2)),
            updatedAt: DateCoding.decode(optionalText(statement, 3)),
            folderPath: optionalText(statement, 4)
        )
    }

    private func transaction(_ work: () throws -> Void) throws {
        lock.lock()
        defer { lock.unlock() }
        try execute("BEGIN IMMEDIATE")
        do {
            try work()
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func execute(_ sql: String, values: [Value] = []) throws {
        lock.lock()
        defer { lock.unlock() }
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }
        try bind(values, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.step(errorMessage(prefix: "SQLite could not run a statement"))
        }
    }

    private func query<T>(
        _ sql: String,
        values: [Value] = [],
        map: (OpaquePointer) throws -> T
    ) throws -> [T] {
        lock.lock()
        defer { lock.unlock() }
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }
        try bind(values, to: statement)

        var rows: [T] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                rows.append(try map(statement))
            case SQLITE_DONE:
                return rows
            default:
                throw DatabaseError.step(errorMessage(prefix: "SQLite could not read rows"))
            }
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw DatabaseError.prepare(errorMessage(prefix: "SQLite could not prepare a statement"))
        }
        return statement
    }

    private func bind(_ values: [Value], to statement: OpaquePointer) throws {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch value {
            case let .text(value):
                result = sqlite3_bind_text(statement, index, value, -1, Self.sqliteTransient)
            case let .double(value):
                result = sqlite3_bind_double(statement, index, value)
            case let .integer(value):
                result = sqlite3_bind_int64(statement, index, value)
            case .null:
                result = sqlite3_bind_null(statement, index)
            }
            guard result == SQLITE_OK else {
                throw DatabaseError.bind(errorMessage(prefix: "SQLite could not bind a value"))
            }
        }
    }

    private func text(_ statement: OpaquePointer, _ index: Int32) -> String {
        optionalText(statement, index) ?? ""
    }

    private func optionalText(_ statement: OpaquePointer, _ index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let value = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: value)
    }

    private func optionalDouble(_ statement: OpaquePointer, _ index: Int32) -> Double? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return sqlite3_column_double(statement, index)
    }

    private func errorMessage(prefix: String) -> String {
        "\(prefix): \(String(cString: sqlite3_errmsg(connection)))"
    }

    private static func escapeLike(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    private static func searchTerms(from question: String) -> [String] {
        let ignored: Set<String> = [
            "about", "after", "and", "are", "before", "could", "cover", "covered",
            "describe", "did", "discuss", "discussed", "does", "explain", "from",
            "have", "into", "made", "meeting", "mention", "mentioned", "our",
            "please", "said", "say", "summarize", "talk", "talked", "tell", "that",
            "the", "their", "there", "they", "this", "was", "were", "what", "when",
            "where", "which", "who", "why", "with",
        ]
        return question
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 2 && !ignored.contains($0) }
            .uniqued()
            .prefix(8)
            .map { $0 }
    }

    private static func extractMarkdown(from rawJSON: String) -> String {
        guard let data = rawJSON.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return rawJSON
        }
        return object["markdown"] as? String
            ?? object["display_markdown"] as? String
            ?? object["raw_summary"] as? String
            ?? rawJSON
    }

    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private enum Value {
        case text(String)
        case double(Double)
        case integer(Int64)
        case null
    }
}

private struct ResolvedAskMeetingScope {
    let meetingIDs: [String]
    let matchedTitleTerms: Set<String>

    static let empty = ResolvedAskMeetingScope(meetingIDs: [], matchedTitleTerms: [])
}

private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
