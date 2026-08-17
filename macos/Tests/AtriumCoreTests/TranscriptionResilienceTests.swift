@testable import AtriumCore
import Foundation
import Testing

@Suite("Transcription resilience")
struct TranscriptionResilienceTests {
    @Test("A long recording is covered by overlapping windows")
    func windowCoverage() {
        let windows = SpeechAudioWindow.windows(covering: 2_970, length: 45, overlap: 2)

        #expect(windows.count == 70)
        #expect(windows[0] == SpeechAudioWindow.Window(index: 0, start: 0, duration: 45))
        #expect(windows[1].start == 43)
        #expect(windows.last?.end == 2_970)
        // Every seam shares audio, so a word across it is still recognized.
        for (earlier, later) in zip(windows, windows.dropFirst()) {
            #expect(later.start < earlier.end)
        }
    }

    @Test("A recording shorter than one window needs one request")
    func shortRecordingWindow() {
        #expect(SpeechAudioWindow.windows(covering: 12) == [
            SpeechAudioWindow.Window(index: 0, start: 0, duration: 12),
        ])
        #expect(SpeechAudioWindow.windows(covering: 0).isEmpty)
    }

    @Test("Window timing becomes recording timing, and a seam is counted once")
    func windowPlacement() {
        let windows = SpeechAudioWindow.windows(covering: 130, length: 45, overlap: 2)
        // Both windows recognize the words at recording second 44, because they
        // share that audio: window 0 covers 0–45 and window 1 covers 43–88.
        let first = SpeechAudioWindow.place(
            [
                SpeechRecognitionSegment(text: "opening", startTime: 0.5, duration: 1),
                SpeechRecognitionSegment(text: "seam", startTime: 44, duration: 0.5),
            ],
            in: windows[0],
            of: windows.count
        )
        let second = SpeechAudioWindow.place(
            [SpeechRecognitionSegment(text: "seam", startTime: 1, duration: 0.5)],
            in: windows[1],
            of: windows.count
        )

        // Window timing becomes recording timing.
        #expect(first.map(\.startTime) == [0.5])
        #expect(second.map(\.startTime) == [44])
        // The shared words belong to one window only, so they are written once.
        #expect(first.map(\.text) == ["opening"])
        #expect(second.map(\.text) == ["seam"])
    }

    @Test("A failed transcription keeps the speech it already recognized")
    @MainActor
    func failedTranscriptionKeepsPartialTranscript() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-partial-test-\(UUID().uuidString)", isDirectory: true)
        let recordings = root.appendingPathComponent("recordings", isDirectory: true)
        let folder = recordings.appendingPathComponent("meeting", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        FileManager.default.createFile(
            atPath: folder.appendingPathComponent("audio.m4a").path,
            contents: Data([0x01])
        )
        let store = try AppStore(
            databaseURL: root.appendingPathComponent("atrium.db"),
            transcription: InterruptedTranscriptionService(),
            recordingsFolder: { recordings }
        )
        let meeting = try store.database.createMeeting(
            title: "Long meeting",
            folderPath: folder.path
        )
        store.select(.meeting(meeting.id))

        store.beginRetranscription()
        await Self.waitForReport(from: store)

        let saved = try store.database.fetchTranscripts(meetingID: meeting.id)
        #expect(saved.map(\.text) == ["Words before the failure"])
        #expect(store.errorMessage?.contains("part of this transcript") == true)
        // The banner names the cause, not only the action that failed.
        #expect(store.errorMessage?.contains("The recognizer stopped") == true)
    }

    @Test("A transcript already saved is not replaced by a failed run")
    @MainActor
    func failedTranscriptionKeepsExistingTranscript() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("atrium-existing-test-\(UUID().uuidString)", isDirectory: true)
        let recordings = root.appendingPathComponent("recordings", isDirectory: true)
        let folder = recordings.appendingPathComponent("meeting", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        FileManager.default.createFile(
            atPath: folder.appendingPathComponent("audio.m4a").path,
            contents: Data([0x01])
        )
        let store = try AppStore(
            databaseURL: root.appendingPathComponent("atrium.db"),
            transcription: InterruptedTranscriptionService(),
            recordingsFolder: { recordings }
        )
        let meeting = try store.database.createMeeting(
            title: "Long meeting",
            folderPath: folder.path
        )
        try store.database.insertTranscripts([
            TranscriptSegment(
                id: "segment-existing",
                meetingID: meeting.id,
                text: "The transcript from the first run",
                timestamp: "00:00",
                audioStartTime: 0,
                audioEndTime: 2,
                duration: 2,
                speaker: "mic"
            ),
        ])
        store.select(.meeting(meeting.id))

        store.beginRetranscription()
        await Self.waitForReport(from: store)

        let saved = try store.database.fetchTranscripts(meetingID: meeting.id)
        #expect(saved.map(\.text) == ["The transcript from the first run"])
    }

    /// Retranscription runs on its own task and reports through `errorMessage`.
    @MainActor
    private static func waitForReport(from store: AppStore) async {
        for _ in 0..<10_000 where store.errorMessage == nil {
            await Task.yield()
        }
    }

    @Test("A failure message names the cause when Atrium wrote one")
    func failureMessagesNameTheCause() {
        let presentable = AppStore.message(
            "Atrium could not finish this recording.",
            explaining: SpeechTranscriptionError.modelUnavailable
        )
        let opaque = AppStore.message(
            "Atrium could not finish this recording.",
            explaining: NSError(domain: "Test", code: 7)
        )

        #expect(presentable.contains("not installed"))
        #expect(opaque == "Atrium could not finish this recording.")
    }

    @Test("Diagnostics carry a stable code without user content")
    func diagnosticCodes() {
        #expect(SpeechTranscriptionError.noSpeech.diagnosticCode == "speech_no_speech")
        #expect(SystemAudioCaptureError.accessDenied.diagnosticCode == "system_audio_access_denied")
        #expect(NSError(domain: "kAFAssistantErrorDomain", code: 1_101).diagnosticCode
            == "kAFAssistantErrorDomain#1101")
    }
}

/// Reports recognized speech and then fails, as a long recognition can.
@MainActor
private final class InterruptedTranscriptionService: SpeechTranscribing {
    func requestPermission() async -> Bool { true }

    func transcribe(
        audioURL _: URL,
        localeIdentifier _: String,
        onProgress: @escaping @MainActor ([SpeechRecognitionSegment]) -> Void
    ) async throws -> [SpeechRecognitionSegment] {
        onProgress([
            SpeechRecognitionSegment(text: "Words before the failure", startTime: 0, duration: 2),
        ])
        throw SpeechTranscriptionError.failed("The recognizer stopped.")
    }

    func cancel() {}
}
