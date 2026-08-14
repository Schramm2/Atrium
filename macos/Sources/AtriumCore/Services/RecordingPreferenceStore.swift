import Foundation

public enum RecordingPreferenceStore {
    public static let folderKey = "notive.recording.folder"
    public static let savesAudioKey = "notive.recording.save-audio"

    public static var defaultFolder: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Movies/notive-recordings", isDirectory: true)
    }

    public static func folder(defaults: UserDefaults = .standard) -> URL {
        guard let path = defaults.string(forKey: folderKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !path.isEmpty else {
            return defaultFolder
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    public static func migrateLegacyPreferences(
        from applicationSupportURL: URL,
        defaults: UserDefaults = .standard
    ) throws {
        let url = applicationSupportURL
            .appendingPathComponent("recording_preferences.json", isDirectory: false)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let data = try Data(contentsOf: url)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let preferences = root["preferences"] as? [String: Any] else {
            return
        }

        if defaults.object(forKey: folderKey) == nil,
           let path = preferences["save_folder"] as? String,
           !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(path, forKey: folderKey)
        }
        if defaults.object(forKey: savesAudioKey) == nil,
           let savesAudio = preferences["auto_save"] as? Bool {
            defaults.set(savesAudio, forKey: savesAudioKey)
        }
    }

    public static func removeRecordedAudio(
        from folder: URL,
        fileManager: FileManager = .default
    ) throws {
        for name in ["microphone.wav", "system-audio.m4a", "audio.m4a"] {
            let url = folder.appendingPathComponent(name, isDirectory: false)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }
}
