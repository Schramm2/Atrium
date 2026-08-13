import Foundation

/// Meeting data left on this Mac by an earlier Notive installation.
public struct PreviousInstallation: Equatable, Sendable {
    public let databaseURL: URL
    public let survey: MeetingDataSurvey
    /// The meetings in the earlier database that are not already in the active database.
    ///
    /// This is populated when the active database is available. Callers that only have a
    /// survey can omit it and it defaults to the number of meetings in that survey.
    public let importableMeetingCount: Int

    public init(
        databaseURL: URL,
        survey: MeetingDataSurvey,
        importableMeetingCount: Int? = nil
    ) {
        self.databaseURL = databaseURL
        self.survey = survey
        self.importableMeetingCount = importableMeetingCount ?? survey.meetingCount
    }

    public var applicationSupportURL: URL {
        databaseURL.deletingLastPathComponent()
    }

    public var meetingCount: Int { survey.meetingCount }
    public var transcriptCount: Int { survey.transcriptCount }
    public var latestMeetingDate: Date? { survey.latestMeetingDate }
}

public struct PreviousInstallationImport: Equatable, Sendable {
    public let importedMeetingCount: Int
    public let skippedMeetingCount: Int
    public let copiedRecordingCount: Int
}

/// Finds meeting data from an earlier Notive installation and copies it into the current one.
///
/// Removing Notive leaves its meeting data in Application Support, so a new installation can
/// take that data back. Notive stored the data under the bundle identifier until it moved to
/// the `Notive` folder, and the earlier folder is the first place to look.
public enum PreviousInstallationService {
    /// The earlier folders searched for meeting data, most recent naming first.
    public static func defaultSearchURLs(fileManager: FileManager = .default) -> [URL] {
        [try? SQLiteDatabase.legacyDatabaseURL(fileManager: fileManager)].compactMap(\.self)
    }

    /// Returns the first searched database that holds meetings, ignoring the one in use.
    public static func find(
        in searchURLs: [URL],
        currentDatabaseURL: URL?,
        fileManager: FileManager = .default
    ) -> PreviousInstallation? {
        let current = currentDatabaseURL?.standardizedFileURL.path
        for url in searchURLs where url.standardizedFileURL.path != current {
            if let survey = SQLiteDatabase.survey(at: url) {
                return PreviousInstallation(databaseURL: url, survey: survey)
            }
        }
        return nil
    }

    public static func find(currentDatabaseURL: URL?) -> PreviousInstallation? {
        find(in: defaultSearchURLs(), currentDatabaseURL: currentDatabaseURL)
    }

    /// Copies the meetings Notive does not hold yet, and brings their recordings with them.
    public static func restore(
        _ installation: PreviousInstallation,
        into database: SQLiteDatabase,
        recordingsFolder: URL,
        fileManager: FileManager = .default
    ) throws -> PreviousInstallationImport {
        let result = try database.importMeetings(from: installation.databaseURL)
        let copied = copyRecordings(
            for: result.imported,
            into: recordingsFolder,
            database: database,
            fileManager: fileManager
        )
        return PreviousInstallationImport(
            importedMeetingCount: result.importedMeetingCount,
            skippedMeetingCount: result.skippedMeetingCount,
            copiedRecordingCount: copied
        )
    }

    /// Copies each recording folder that sits outside the recordings folder into it.
    ///
    /// A recording already inside the recordings folder keeps its place. A recording folder
    /// that no longer exists keeps its recorded path, so the meeting still shows where its
    /// audio was.
    private static func copyRecordings(
        for meetings: [Meeting],
        into recordingsFolder: URL,
        database: SQLiteDatabase,
        fileManager: FileManager
    ) -> Int {
        var copied = 0
        for meeting in meetings {
            guard let path = meeting.folderPath?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !path.isEmpty else { continue }
            let source = URL(fileURLWithPath: path, isDirectory: true)
            guard isDirectory(source, fileManager: fileManager),
                  !isContained(source, in: recordingsFolder) else { continue }
            do {
                try fileManager.createDirectory(
                    at: recordingsFolder,
                    withIntermediateDirectories: true
                )
                let destination = availableURL(
                    named: source.lastPathComponent,
                    in: recordingsFolder,
                    fileManager: fileManager
                )
                try fileManager.copyItem(at: source, to: destination)
                try database.updateMeetingFolderPath(id: meeting.id, folderPath: destination.path)
                copied += 1
            } catch {
                DiagnosticLogger.failure(operation: "previous_recording_copy", error: error)
            }
        }
        return copied
    }

    private static func isDirectory(_ url: URL, fileManager: FileManager) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private static func isContained(_ url: URL, in folder: URL) -> Bool {
        let path = url.standardizedFileURL.pathComponents
        let folderPath = folder.standardizedFileURL.pathComponents
        guard path.count > folderPath.count else { return false }
        return Array(path.prefix(folderPath.count)) == folderPath
    }

    private static func availableURL(
        named name: String,
        in folder: URL,
        fileManager: FileManager
    ) -> URL {
        let candidate = folder.appendingPathComponent(name, isDirectory: true)
        guard fileManager.fileExists(atPath: candidate.path) else { return candidate }
        for suffix in 2...99 {
            let next = folder.appendingPathComponent("\(name) \(suffix)", isDirectory: true)
            if !fileManager.fileExists(atPath: next.path) { return next }
        }
        return folder.appendingPathComponent("\(name) \(UUID().uuidString)", isDirectory: true)
    }
}
