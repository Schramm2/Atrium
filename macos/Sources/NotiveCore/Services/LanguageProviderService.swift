import Foundation

public enum LanguageProviderError: LocalizedError {
    case missingAPIKey
    case invalidEndpoint
    case invalidResponse
    case requestFailed(Int, String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Enter an API key for the selected AI service, then try again."
        case .invalidEndpoint:
            "Enter a valid service URL, then try again."
        case .invalidResponse:
            "The AI service returned an answer that Notive could not use. Try again."
        case .requestFailed:
            "The AI service could not complete the request. Check its settings and try again."
        }
    }
}

public actor LanguageProviderService {
    public init() {}

    public func generate(
        instructions: String,
        prompt: String,
        configuration: AIConfiguration
    ) async throws -> String {
        switch configuration.provider {
        case .apple:
            throw LanguageProviderError.invalidEndpoint
        case .ollama:
            return try await ollama(instructions: instructions, prompt: prompt, configuration: configuration)
        case .anthropic:
            return try await anthropic(instructions: instructions, prompt: prompt, configuration: configuration)
        case .openAI, .groq, .openRouter, .customOpenAI:
            return try await openAICompatible(
                instructions: instructions,
                prompt: prompt,
                configuration: configuration
            )
        }
    }

    private func ollama(
        instructions: String,
        prompt: String,
        configuration: AIConfiguration
    ) async throws -> String {
        guard let base = URL(string: configuration.endpoint) else {
            throw LanguageProviderError.invalidEndpoint
        }
        let url = base.appendingPathComponent("api/chat")
        let body: [String: Any] = [
            "model": configuration.model,
            "stream": false,
            "messages": messages(instructions: instructions, prompt: prompt),
        ]
        let object = try await request(url: url, body: body, headers: [:])
        guard let message = object["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LanguageProviderError.invalidResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func openAICompatible(
        instructions: String,
        prompt: String,
        configuration: AIConfiguration
    ) async throws -> String {
        if configuration.provider != .customOpenAI && configuration.apiKey.isEmpty {
            throw LanguageProviderError.missingAPIKey
        }
        let endpoint: String
        switch configuration.provider {
        case .openAI: endpoint = "https://api.openai.com/v1"
        case .groq: endpoint = "https://api.groq.com/openai/v1"
        case .openRouter: endpoint = "https://openrouter.ai/api/v1"
        default: endpoint = configuration.endpoint
        }
        guard let base = URL(string: endpoint) else {
            throw LanguageProviderError.invalidEndpoint
        }
        let url = base.appendingPathComponent("chat/completions")
        let body: [String: Any] = [
            "model": configuration.model,
            "messages": messages(instructions: instructions, prompt: prompt),
            "temperature": 0.2,
        ]
        var headers: [String: String] = [:]
        if !configuration.apiKey.isEmpty { headers["Authorization"] = "Bearer \(configuration.apiKey)" }
        let object = try await request(url: url, body: body, headers: headers)
        guard let choices = object["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LanguageProviderError.invalidResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func anthropic(
        instructions: String,
        prompt: String,
        configuration: AIConfiguration
    ) async throws -> String {
        guard !configuration.apiKey.isEmpty else { throw LanguageProviderError.missingAPIKey }
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        let body: [String: Any] = [
            "model": configuration.model,
            "system": instructions,
            "max_tokens": 2_000,
            "messages": [["role": "user", "content": prompt]],
        ]
        let object = try await request(
            url: url,
            body: body,
            headers: [
                "x-api-key": configuration.apiKey,
                "anthropic-version": "2023-06-01",
            ]
        )
        guard let content = object["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw LanguageProviderError.invalidResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func request(
        url: URL,
        body: [String: Any],
        headers: [String: String]
    ) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw LanguageProviderError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LanguageProviderError.requestFailed(response.statusCode, String(message.prefix(500)))
        }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LanguageProviderError.invalidResponse
        }
        return object
    }

    private func messages(instructions: String, prompt: String) -> [[String: String]] {
        [
            ["role": "system", "content": instructions],
            ["role": "user", "content": prompt],
        ]
    }
}
