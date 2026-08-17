@testable import AtriumCore
import AVFAudio
import Foundation
import Speech
import Testing

@Suite("Recording support")
struct RecordingSupportTests {
    @Test("Audio application permission drives microphone authorization")
    func microphonePermissionMapping() {
        #expect(MicrophoneAuthorization.status(for: .granted) == .authorized)
        #expect(MicrophoneAuthorization.status(for: .denied) == .denied)
        #expect(MicrophoneAuthorization.status(for: .undetermined) == .notDetermined)
    }

    @Test("A stalled microphone permission request returns control")
    func stalledMicrophonePermissionRequest() async {
        let granted = await MicrophoneAuthorization.request(timeout: .milliseconds(10)) { _ in }

        #expect(!granted)
    }

    @Test("A stalled speech permission request returns control")
    func stalledSpeechPermissionRequest() async {
        let status = await SpeechAuthorization.request(timeout: .milliseconds(10)) { _ in }

        #expect(status == .denied)
    }

    @Test("Speech timing becomes ordered database transcript timing")
    @MainActor
    func transcriptTiming() {
        let recognized = [
            SpeechRecognitionSegment(text: "First", startTime: 3.2, duration: 0.8),
            SpeechRecognitionSegment(text: "Second", startTime: 64.1, duration: 1.4),
        ]

        let segments = AppStore.transcriptSegments(
            from: recognized,
            meetingID: "meeting-1",
            speaker: "system"
        )

        #expect(segments.map(\.timestamp) == ["00:03", "01:04"])
        #expect(segments.map(\.speaker) == ["system", "system"])
        #expect(segments[1].audioEndTime == 65.5)
    }

    @Test("Meeting audio lookup prefers the primary recording")
    func audioLookup() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-audio-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let alternate = folder.appendingPathComponent("import.wav")
        let primary = folder.appendingPathComponent("audio.m4a")
        FileManager.default.createFile(atPath: alternate.path, contents: Data())
        FileManager.default.createFile(atPath: primary.path, contents: Data())

        #expect(
            MeetingAudioFiles.primary(in: folder.path)?.resolvingSymlinksInPath()
                == primary.resolvingSymlinksInPath()
        )
    }

    @Test("Microphone-only mixing creates a real M4A playback file")
    func microphoneOnlyMixing() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-mix-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let microphoneURL = folder.appendingPathComponent("microphone.wav")
        let outputURL = folder.appendingPathComponent("audio.m4a")
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        do {
            let file = try AVAudioFile(forWriting: microphoneURL, settings: format.settings)
            let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16_000))
            buffer.frameLength = 16_000
            try file.write(from: buffer)
        }

        _ = try await AudioMixingService().mix(
            microphoneURL: microphoneURL,
            systemAudioURL: nil,
            outputURL: outputURL
        )

        let data = try Data(contentsOf: outputURL, options: .mappedIfSafe)
        let microphoneData = try Data(contentsOf: microphoneURL, options: .mappedIfSafe)
        #expect(data.count > 12)
        #expect(String(decoding: data[4..<8], as: UTF8.self) == "ftyp")
        #expect(data != microphoneData)
    }

    @Test("Adjacent recognized words form readable utterances")
    @MainActor
    func utterances() {
        let recognized = [
            SpeechRecognitionSegment(text: "We", startTime: 0, duration: 0.2),
            SpeechRecognitionSegment(text: "agreed", startTime: 0.25, duration: 0.4),
            SpeechRecognitionSegment(text: "Today", startTime: 2, duration: 0.4),
        ]

        let segments = AppStore.transcriptSegments(from: recognized, meetingID: "meeting-1")

        #expect(segments.count == 2)
        #expect(segments.first?.text == "We agreed")
        #expect(segments.first?.duration == 0.65)
    }

    @Test("Voice features receive stable anonymous labels")
    func voiceLabels() {
        let labels = VoiceClusterService.labels(
            for: [
                [1, 0, 0],
                [0.99, 0.01, 0],
                [0, 1, 0],
                [0.98, 0.02, 0],
            ],
            threshold: 0.94
        )

        #expect(labels == ["Speaker 1", "Speaker 1", "Speaker 2", "Speaker 1"])
    }

    @Test("Real-time capture state can be read while audio frames arrive")
    func realtimeCaptureState() async {
        let state = RealtimeCaptureState()
        state.reset(sampleRate: 48_000)

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for _ in 0..<100 {
                    state.record(frameCount: 480, power: -24)
                }
            }
            group.addTask {
                for _ in 0..<100 {
                    _ = state.snapshot()
                }
            }
        }

        let snapshot = state.snapshot()
        #expect(snapshot.currentTime == 1)
        #expect(snapshot.averagePower == -24)
        state.setAcceptsAudio(false)
        #expect(!state.shouldAcceptAudio())
    }

    @Test("Cancelling capture releases the microphone audio engine")
    @MainActor
    func captureCancellationReleasesEngine() {
        let service = LiveMeetingCaptureService()
        let activeEngine = service.audioEngineIdentity

        service.cancel()

        #expect(service.audioEngineIdentity != activeEngine)
    }

    @Test("Legacy recording preferences migrate without replacing native choices")
    func recordingPreferenceMigration() throws {
        let suiteName = "atrium-recording-preferences-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let support = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-preferences-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: support) }
        let data = try JSONSerialization.data(withJSONObject: [
            "preferences": [
                "save_folder": "/tmp/legacy-atrium-recordings",
                "auto_save": false,
            ],
        ])
        try data.write(to: support.appendingPathComponent("recording_preferences.json"))

        try RecordingPreferenceStore.migrateLegacyPreferences(from: support, defaults: defaults)
        #expect(defaults.string(forKey: RecordingPreferenceStore.folderKey) == "/tmp/legacy-atrium-recordings")
        #expect(defaults.bool(forKey: RecordingPreferenceStore.savesAudioKey) == false)

        defaults.set("/tmp/native-atrium-recordings", forKey: RecordingPreferenceStore.folderKey)
        defaults.set(true, forKey: RecordingPreferenceStore.savesAudioKey)
        try RecordingPreferenceStore.migrateLegacyPreferences(from: support, defaults: defaults)
        #expect(defaults.string(forKey: RecordingPreferenceStore.folderKey) == "/tmp/native-atrium-recordings")
        #expect(defaults.bool(forKey: RecordingPreferenceStore.savesAudioKey))
    }

    @Test("Audio cleanup removes recordings but keeps imported source copies")
    func recordingAudioCleanup() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-cleanup-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for name in ["microphone.wav", "system-audio.m4a", "audio.m4a", "import.aiff"] {
            FileManager.default.createFile(
                atPath: folder.appendingPathComponent(name).path,
                contents: Data([0x01])
            )
        }

        try RecordingPreferenceStore.removeRecordedAudio(from: folder)

        #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent("microphone.wav").path))
        #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent("system-audio.m4a").path))
        #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent("audio.m4a").path))
        #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent("import.aiff").path))
    }

    @Test("Cancelled audio copies do not leave partial imports")
    func cancelledAudioCopy() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-copy-cancel-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appendingPathComponent("source.aiff")
        let destination = folder.appendingPathComponent("destination.aiff")
        try Data([0x01, 0x02, 0x03]).write(to: source)
        let service = AudioImportService()

        let task = Task { try await service.copy(from: source, to: destination) }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(!FileManager.default.fileExists(atPath: destination.path))
    }

    @Test("Cancelling an import removes its partial meeting and copied file")
    @MainActor
    func importCancellationCleanup() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-import-cancel-test-\(UUID().uuidString)", isDirectory: true)
        let recordings = root.appendingPathComponent("recordings", isDirectory: true)
        try FileManager.default.createDirectory(at: recordings, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("synthetic.aiff")
        try Data([0x01, 0x02, 0x03]).write(to: source)
        let transcription = WaitingTranscriptionService()
        let store = try AppStore(
            databaseURL: root.appendingPathComponent("atrium.db"),
            transcription: transcription,
            recordingsFolder: { recordings }
        )

        let task = Task { await store.importAudio(from: source) }
        while !transcription.started {
            await Task.yield()
        }
        store.cancelImport()
        await task.value

        #expect(store.recordingState == .idle)
        #expect(!store.isImportingAudio)
        #expect(store.meetings.isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: recordings.path).isEmpty)
        #expect(FileManager.default.fileExists(atPath: source.path))
    }

    @Test("Import copies audio and persists the recognized transcript")
    @MainActor
    func importSuccess() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-import-test-\(UUID().uuidString)", isDirectory: true)
        let recordings = root.appendingPathComponent("recordings", isDirectory: true)
        try FileManager.default.createDirectory(at: recordings, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("synthetic.aiff")
        try Data([0x01, 0x02, 0x03]).write(to: source)
        let store = try AppStore(
            databaseURL: root.appendingPathComponent("atrium.db"),
            transcription: ImmediateTranscriptionService(),
            recordingsFolder: { recordings }
        )

        await store.importAudio(from: source)

        let meeting = try #require(store.meetings.first)
        let transcript = try store.database.fetchTranscripts(meetingID: meeting.id)
        let copiedFolder = URL(
            fileURLWithPath: try #require(meeting.folderPath),
            isDirectory: true
        )
        #expect(store.recordingState == .idle)
        #expect(transcript.map(\.text) == ["Synthetic import completed"])
        #expect(FileManager.default.fileExists(atPath: source.path))
        #expect(
            FileManager.default.fileExists(
                atPath: copiedFolder.appendingPathComponent(source.lastPathComponent).path
            )
        )
    }
}

@MainActor
private final class WaitingTranscriptionService: SpeechTranscribing {
    private(set) var started = false
    private var continuation: CheckedContinuation<[SpeechRecognitionSegment], Error>?

    func requestPermission() async -> Bool { true }

    func transcribe(
        audioURL _: URL,
        localeIdentifier _: String,
        onProgress _: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment] {
        started = true
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func cancel() {
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}

@MainActor
private final class ImmediateTranscriptionService: SpeechTranscribing {
    func requestPermission() async -> Bool { true }

    func transcribe(
        audioURL _: URL,
        localeIdentifier _: String,
        onProgress _: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment] {
        [
            SpeechRecognitionSegment(
                text: "Synthetic import completed",
                startTime: 0,
                duration: 1
            ),
        ]
    }

    func cancel() {}
}
