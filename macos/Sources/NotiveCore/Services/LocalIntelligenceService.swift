import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public enum LocalIntelligenceError: LocalizedError {
    case emptyTranscript

    public var errorDescription: String? {
        switch self {
        case .emptyTranscript:
            "Notive needs a transcript before it can generate this content."
        }
    }
}

public actor LocalIntelligenceService {
    private let providerService = LanguageProviderService()

    public init() {}

    public func summarize(
        _ segments: [TranscriptSegment],
        language: String? = nil,
        customPrompt: String = ""
    ) async throws -> String {
        let transcript = Self.transcriptText(segments)
        guard !transcript.isEmpty else { throw LocalIntelligenceError.emptyTranscript }
        let configuration = AIConfiguration.load()
        let summaryInstructions = Self.summaryInstructions(
            language: language,
            customPrompt: customPrompt
        )

        if configuration.provider != .apple {
            return try await providerService.generate(
                instructions: summaryInstructions,
                prompt: transcript,
                configuration: configuration
            )
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), SystemLanguageModel.default.availability == .available {
            let session = LanguageModelSession(
                instructions: summaryInstructions
            )
            let response = try await session.respond(to: transcript)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        #endif

        return Self.extractiveSummary(segments)
    }

    public func answer(
        question: String,
        evidence: [AskEvidence]
    ) async throws -> AskAnswer {
        guard !evidence.isEmpty else {
            return AskAnswer(claims: [], citations: [], provider: "local", model: "evidence-only")
        }

        let sourceText = Self.boundedSourceText(evidence)
        let configuration = AIConfiguration.load()

        if configuration.provider != .apple {
            let content = try await providerService.generate(
                instructions: "Answer using only the supplied meeting sources. State uncertainty. Do not invent facts or source identifiers.",
                prompt: "Question: \(question)\n\nSources:\n\(sourceText)",
                configuration: configuration
            )
            return AskAnswer(
                claims: [AskClaim(text: content, citationIDs: evidence.map(\.id))],
                citations: evidence,
                provider: configuration.provider.title,
                model: configuration.model
            )
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), SystemLanguageModel.default.availability == .available {
            let session = LanguageModelSession(
                instructions: """
                Answer questions using only the supplied meeting sources. State uncertainty when needed.
                Keep the answer concise. Do not add a source list or invent source identifiers.
                """
            )
            let response = try await session.respond(
                to: "Question: \(question)\n\nSources:\n\(sourceText)"
            )
            let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let claim = AskClaim(text: content, citationIDs: evidence.map(\.id))
            return AskAnswer(
                claims: [claim],
                citations: evidence,
                provider: "Apple Intelligence",
                model: "on-device"
            )
        }
        #endif

        return Self.extractiveAnswer(evidence: evidence)
    }

    static func extractiveSummary(_ segments: [TranscriptSegment]) -> String {
        let sentences = segments
            .map(\.text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !sentences.isEmpty else { return "" }

        let overview = sentences.prefix(5).map { "- \($0)" }.joined(separator: "\n")
        let actions = sentences.filter { sentence in
            let value = sentence.lowercased()
            return ["will ", "need to", "action", "follow up", "next step", "should "]
                .contains { value.contains($0) }
        }.prefix(8)
        let decisions = sentences.filter { sentence in
            let value = sentence.lowercased()
            return ["decided", "agreed", "approved", "we'll use", "will use"]
                .contains { value.contains($0) }
        }.prefix(8)

        var sections = ["# Overview\n\(overview)"]
        if !decisions.isEmpty {
            sections.append("# Decisions\n\(decisions.map { "- \($0)" }.joined(separator: "\n"))")
        }
        if !actions.isEmpty {
            sections.append("# Action Items\n\(actions.map { "- \($0)" }.joined(separator: "\n"))")
        }
        return sections.joined(separator: "\n\n")
    }

    static func extractiveAnswer(evidence: [AskEvidence]) -> AskAnswer {
        let claims = evidence.prefix(3).map { source in
            AskClaim(text: source.context, citationIDs: [source.id])
        }
        return AskAnswer(
            claims: claims,
            citations: evidence,
            provider: "Local evidence",
            model: "extractive"
        )
    }

    static func boundedSourceText(
        _ evidence: [AskEvidence],
        maximumCharacters: Int = 6_000,
        maximumSourceCharacters: Int = 600
    ) -> String {
        var remaining = maximumCharacters
        var lines: [String] = []
        for source in evidence where remaining > 0 {
            let context = String(source.context.prefix(maximumSourceCharacters))
            let line = "[\(source.id)] \(source.meetingTitle), \(source.timestamp): \(context)"
            let bounded = String(line.prefix(remaining))
            guard !bounded.isEmpty else { break }
            lines.append(bounded)
            remaining -= bounded.count + 1
        }
        return lines.joined(separator: "\n")
    }

    private static func transcriptText(_ segments: [TranscriptSegment]) -> String {
        segments.map { segment in
            let speaker = segment.resolvedSpeaker.map { "\($0): " } ?? ""
            return "[\(segment.timestamp)] \(speaker)\(segment.text)"
        }.joined(separator: "\n")
    }

    static func summaryInstructions(language requested: String?, customPrompt: String) -> String {
        let template = SummaryTemplate(
            rawValue: UserDefaults.standard.string(forKey: "notive.summary.template") ?? "standard_meeting"
        ) ?? .standard
        let languageInstruction = MeetingSummaryPreferenceStore.languageTitle(for: requested)
            .map { "Write the result in \($0)." }
            ?? "Use the main language of the transcript."
        var instructions = """
        Write a concise Markdown meeting summary using only the supplied transcript. Do not invent facts.
        \(template.sectionInstruction) Omit empty sections. \(languageInstruction)
        """
        let additionalInstruction = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !additionalInstruction.isEmpty {
            instructions += "\nAdditional user instruction: \(additionalInstruction)"
        }
        return instructions
    }
}
