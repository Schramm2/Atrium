@testable import NotiveCore
import Foundation
import Testing

@Suite("Local intelligence fallbacks")
struct LocalIntelligenceTests {
    @Test("Extractive summaries preserve supported decisions and actions")
    func summary() {
        let segments = [
            segment("We agreed to ship the native beta on Friday."),
            segment("Maya will follow up with the design team."),
            segment("The team reviewed the current migration status."),
        ]

        let summary = LocalIntelligenceService.extractiveSummary(segments)

        #expect(summary.contains("# Overview"))
        #expect(summary.contains("# Decisions"))
        #expect(summary.contains("# Action Items"))
        #expect(summary.contains("Maya will follow up"))
    }

    @Test("Extractive answers keep each claim tied to its source")
    func answer() {
        let evidence = [
            AskEvidence(
                id: "S1",
                meetingID: "meeting-1",
                meetingTitle: "Planning",
                transcriptID: "segment-1",
                snippet: "Ship on Friday.",
                context: "The team agreed to ship on Friday.",
                timestamp: "00:10",
                meetingCreatedAt: .now,
                score: 1
            ),
        ]

        let answer = LocalIntelligenceService.extractiveAnswer(evidence: evidence)

        #expect(answer.claims.count == 1)
        #expect(answer.claims.first?.citationIDs == ["S1"])
        #expect(answer.citations == evidence)
    }

    @Test("Ask prompts bound long local transcript context")
    func boundedAskContext() {
        let evidence = (1...12).map { index in
            AskEvidence(
                id: "S\(index)",
                meetingID: "meeting-1",
                meetingTitle: "Planning",
                transcriptID: "segment-\(index)",
                snippet: "Evidence",
                context: String(repeating: "long transcript context ", count: 100),
                timestamp: "00:10",
                meetingCreatedAt: .now,
                score: 1
            )
        }

        let prompt = LocalIntelligenceService.boundedSourceText(evidence)

        #expect(prompt.count <= 6_000)
        #expect(prompt.contains("[S1]"))
        #expect(prompt.split(separator: "\n").allSatisfy { $0.count <= 700 })
    }

    private func segment(_ text: String) -> TranscriptSegment {
        TranscriptSegment(
            id: UUID().uuidString,
            meetingID: "meeting-1",
            text: text,
            timestamp: "00:00"
        )
    }
}
