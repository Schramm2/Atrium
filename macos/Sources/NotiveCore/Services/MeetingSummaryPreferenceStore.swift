import Foundation

public struct SummaryLanguageOption: Identifiable, Hashable, Sendable {
    public let code: String
    public let title: String

    public var id: String { code }
}

public enum MeetingSummaryPreferenceStore {
    public static let defaultKey = "notive.summary.language"
    public static let supportedLanguages = [
        SummaryLanguageOption(code: "en", title: "English"),
        SummaryLanguageOption(code: "zh", title: "Chinese"),
        SummaryLanguageOption(code: "zh-tw", title: "Traditional Chinese"),
        SummaryLanguageOption(code: "de", title: "German"),
        SummaryLanguageOption(code: "es", title: "Spanish"),
        SummaryLanguageOption(code: "ru", title: "Russian"),
        SummaryLanguageOption(code: "ko", title: "Korean"),
        SummaryLanguageOption(code: "fr", title: "French"),
        SummaryLanguageOption(code: "ja", title: "Japanese"),
        SummaryLanguageOption(code: "pt", title: "Portuguese"),
        SummaryLanguageOption(code: "it", title: "Italian"),
        SummaryLanguageOption(code: "nl", title: "Dutch"),
        SummaryLanguageOption(code: "pl", title: "Polish"),
        SummaryLanguageOption(code: "ar", title: "Arabic"),
        SummaryLanguageOption(code: "hi", title: "Hindi"),
        SummaryLanguageOption(code: "ta", title: "Tamil"),
        SummaryLanguageOption(code: "tr", title: "Turkish"),
        SummaryLanguageOption(code: "vi", title: "Vietnamese"),
        SummaryLanguageOption(code: "th", title: "Thai"),
        SummaryLanguageOption(code: "id", title: "Indonesian"),
        SummaryLanguageOption(code: "sv", title: "Swedish"),
        SummaryLanguageOption(code: "cs", title: "Czech"),
        SummaryLanguageOption(code: "da", title: "Danish"),
        SummaryLanguageOption(code: "fi", title: "Finnish"),
        SummaryLanguageOption(code: "el", title: "Greek"),
        SummaryLanguageOption(code: "he", title: "Hebrew"),
        SummaryLanguageOption(code: "hu", title: "Hungarian"),
        SummaryLanguageOption(code: "no", title: "Norwegian"),
        SummaryLanguageOption(code: "ro", title: "Romanian"),
        SummaryLanguageOption(code: "uk", title: "Ukrainian"),
    ]

    private static let writeLock = NSLock()
    private static let metadataName = "metadata.json"
    private static let metadataField = "summary_language"

    public static func language(
        for meeting: Meeting,
        defaults: UserDefaults = .standard
    ) throws -> String? {
        guard let folderPath = meeting.folderPath else {
            return normalized(defaults.string(forKey: fallbackKey(meeting.id)))
        }
        let metadataURL = URL(fileURLWithPath: folderPath, isDirectory: true)
            .appendingPathComponent(metadataName)
        guard FileManager.default.fileExists(atPath: metadataURL.path) else { return nil }
        let object = try metadataObject(at: metadataURL)
        return try normalizedStoredValue(object[metadataField])
    }

    public static func save(
        _ language: String?,
        for meeting: Meeting,
        defaults: UserDefaults = .standard
    ) throws {
        let value = try normalizedPreference(language)
        guard let folderPath = meeting.folderPath else {
            if let value {
                defaults.set(value, forKey: fallbackKey(meeting.id))
            } else {
                defaults.removeObject(forKey: fallbackKey(meeting.id))
            }
            return
        }

        try writeLock.withLock {
            let metadataURL = URL(fileURLWithPath: folderPath, isDirectory: true)
                .appendingPathComponent(metadataName)
            var object: [String: Any] = if FileManager.default.fileExists(atPath: metadataURL.path) {
                try metadataObject(at: metadataURL)
            } else {
                [:]
            }
            if let value {
                object[metadataField] = value
            } else {
                object.removeValue(forKey: metadataField)
            }
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: metadataURL, options: .atomic)
        }
        defaults.removeObject(forKey: fallbackKey(meeting.id))
    }

    public static func applyDefault(
        to meeting: Meeting,
        defaults: UserDefaults = .standard
    ) throws {
        let value = defaults.string(forKey: defaultKey)
        guard normalized(value) != nil else { return }
        try save(value, for: meeting, defaults: defaults)
    }

    public static func languageTitle(for code: String?) -> String? {
        guard let code = normalized(code) else { return nil }
        return supportedLanguages.first { $0.code == code }?.title
    }

    private static func fallbackKey(_ meetingID: String) -> String {
        "notive.summary.language.meeting.\(meetingID)"
    }

    private static func metadataObject(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        let value = try JSONSerialization.jsonObject(with: data)
        guard let object = value as? [String: Any] else {
            throw CocoaError(.propertyListReadCorrupt)
        }
        return object
    }

    private static func normalizedStoredValue(_ value: Any?) throws -> String? {
        guard let value else { return nil }
        guard let string = value as? String else { return nil }
        return try normalizedPreference(string)
    }

    private static func normalizedPreference(_ raw: String?) throws -> String? {
        guard let raw else { return nil }
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, cleaned != "auto", cleaned != "__auto__" else { return nil }
        guard let value = normalized(cleaned) else {
            throw CocoaError(.validationMissingMandatoryProperty)
        }
        return value
    }

    private static func normalized(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let value = raw.lowercased().replacingOccurrences(of: "_", with: "-")
        if supportedLanguages.contains(where: { $0.code == value }) { return value }
        if value == "zh-cn" { return "zh" }
        let base = value.split(separator: "-").first.map(String.init)
        return supportedLanguages.contains(where: { $0.code == base }) ? base : nil
    }
}
