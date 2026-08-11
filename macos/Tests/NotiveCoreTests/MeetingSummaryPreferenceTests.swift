@testable import NotiveCore
import Foundation
import Testing

@Suite("Meeting summary preferences")
struct MeetingSummaryPreferenceTests {
    @Test("Metadata language round trip preserves unrelated fields")
    func metadataRoundTrip() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let metadataURL = folder.appendingPathComponent("metadata.json")
        let original = try JSONSerialization.data(withJSONObject: [
            "version": "1.0",
            "detected_summary_language": "es",
            "nested": ["kept": true],
        ])
        try original.write(to: metadataURL)
        let meeting = makeMeeting(folderPath: folder.path)

        try MeetingSummaryPreferenceStore.save("fr-FR", for: meeting)

        #expect(try MeetingSummaryPreferenceStore.language(for: meeting) == "fr")
        let object = try #require(
            JSONSerialization.jsonObject(with: Data(contentsOf: metadataURL)) as? [String: Any]
        )
        #expect(object["summary_language"] as? String == "fr")
        #expect(object["detected_summary_language"] as? String == "es")
        #expect((object["nested"] as? [String: Bool])?["kept"] == true)
    }

    @Test("Auto removes the language override")
    func autoRemovesOverride() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let meeting = makeMeeting(folderPath: folder.path)
        try MeetingSummaryPreferenceStore.save("de", for: meeting)

        try MeetingSummaryPreferenceStore.save("auto", for: meeting)

        #expect(try MeetingSummaryPreferenceStore.language(for: meeting) == nil)
        let data = try Data(contentsOf: folder.appendingPathComponent("metadata.json"))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["summary_language"] == nil)
    }

    @Test("Folderless meetings use isolated local preferences")
    func folderlessFallback() throws {
        let suiteName = "notive-summary-preferences-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let meeting = makeMeeting(folderPath: nil)

        try MeetingSummaryPreferenceStore.save("zh_TW", for: meeting, defaults: defaults)
        #expect(try MeetingSummaryPreferenceStore.language(for: meeting, defaults: defaults) == "zh-tw")

        try MeetingSummaryPreferenceStore.save(nil, for: meeting, defaults: defaults)
        #expect(try MeetingSummaryPreferenceStore.language(for: meeting, defaults: defaults) == nil)
    }

    @Test("Summary instructions include meeting language and custom instruction")
    func summaryInstructions() {
        let instructions = LocalIntelligenceService.summaryInstructions(
            language: "ja",
            customPrompt: "  Focus on risks.  "
        )

        #expect(instructions.contains("Write the result in Japanese."))
        #expect(instructions.contains("Additional user instruction: Focus on risks."))
    }

    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("notive-summary-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func makeMeeting(folderPath: String?) -> Meeting {
        Meeting(
            id: "meeting-\(UUID().uuidString)",
            title: "Summary test",
            createdAt: .now,
            updatedAt: .now,
            folderPath: folderPath
        )
    }
}
