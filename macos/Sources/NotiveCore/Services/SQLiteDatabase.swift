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

public final class SQLiteDatabase: @unchecked Sendable {
    public static let legacyApplicationSupportDirectory = "com.ubundi.meet"
    public static let databaseFilename = "meeting_minutes.sqlite"

    private let connection: OpaquePointer
    private let lock = NSRecursiveLock()

    public static func defaultDatabaseURL(
        fileManager: FileManager = .default
    ) throws -> URL {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return support
            .appendingPathComponent(legacyApplicationSupportDirectory, isDirectory: true)
            .appendingPathComponent(databaseFilename)
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
        let terms = Self.searchTerms(from: question)
        guard !terms.isEmpty else { return [] }

        var filters: [String] = []
        var values: [Value] = [.text(terms.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: " OR "))]

        if !scope.meetingIDs.isEmpty {
            filters.append("m.id IN (\(Array(repeating: "?", count: scope.meetingIDs.count).joined(separator: ", ")))")
            values.append(contentsOf: scope.meetingIDs.sorted().map(Value.text))
        }
        if let dateFrom = scope.dateFrom {
            filters.append("m.created_at >= ?")
            values.append(.text(DateCoding.encode(dateFrom)))
        }
        if let dateTo = scope.dateTo {
            filters.append("m.created_at <= ?")
            values.append(.text(DateCoding.encode(dateTo)))
        }
        values.append(.integer(Int64(limit)))

        let filterSQL = filters.isEmpty ? "" : " AND \(filters.joined(separator: " AND "))"
        let sql = """
            SELECT t.id, t.meeting_id, m.title, t.transcript, t.timestamp,
                   t.audio_start_time, t.speaker, m.created_at,
                   bm25(transcripts_fts) AS rank
            FROM transcripts_fts
            JOIN transcripts t ON t.rowid = transcripts_fts.rowid
            JOIN meetings m ON m.id = t.meeting_id
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

        return try rows.enumerated().map { index, row in
            let context = try neighboringContext(
                meetingID: row.meetingID,
                transcriptID: row.transcriptID,
                fallback: row.snippet
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

    private func neighboringContext(
        meetingID: String,
        transcriptID: String,
        fallback: String
    ) throws -> String {
        let segments = try query(
            """
            WITH target AS (
                SELECT rowid FROM transcripts WHERE id = ? AND meeting_id = ?
            )
            SELECT transcript FROM transcripts, target
            WHERE meeting_id = ? AND rowid BETWEEN target.rowid - 1 AND target.rowid + 1
            ORDER BY rowid
            """,
            values: [.text(transcriptID), .text(meetingID), .text(meetingID)]
        ) { statement in
            self.text(statement, 0)
        }
        return segments.isEmpty ? fallback : segments.joined(separator: " ")
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
            "about", "after", "before", "could", "did", "does", "from", "have",
            "into", "made", "that", "the", "their", "there", "they", "this",
            "was", "were", "what", "when", "where", "which", "who", "with",
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

private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
