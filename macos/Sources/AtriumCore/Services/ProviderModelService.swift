import Foundation

public enum ProviderModelError: LocalizedError {
    case unsupported
    case invalidEndpoint
    case invalidResponse
    case requestFailed(Int, String)

    public var errorDescription: String? {
        switch self {
        case .unsupported:
            "This AI service does not use downloadable models."
        case .invalidEndpoint:
            "Enter a valid model service URL, then try again."
        case .invalidResponse:
            "Atrium could not read the available models. Check the service settings and try again."
        case .requestFailed:
            "The AI service could not load models. Check its settings and try again."
        }
    }
}

public actor ProviderModelService {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func listModels(configuration: AIConfiguration) async throws -> [String] {
        if configuration.provider == .apple { return ["on-device"] }
        let request = try modelListRequest(configuration: configuration)
        let data = try await perform(request)
        return try Self.modelNames(from: data, provider: configuration.provider)
    }

    public func pullOllamaModel(
        name: String,
        configuration: AIConfiguration
    ) async throws {
        guard configuration.provider == .ollama else { throw ProviderModelError.unsupported }
        let url = try endpoint(configuration.endpoint, path: "api/pull")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "name": name,
            "stream": false,
        ])
        _ = try await perform(request)
    }

    public func deleteOllamaModel(
        name: String,
        configuration: AIConfiguration
    ) async throws {
        guard configuration.provider == .ollama else { throw ProviderModelError.unsupported }
        let url = try endpoint(configuration.endpoint, path: "api/delete")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["name": name])
        _ = try await perform(request)
    }

    static func modelNames(from data: Data, provider: AIProvider) throws -> [String] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderModelError.invalidResponse
        }
        let names: [String]
        if provider == .ollama {
            names = (root["models"] as? [[String: Any]] ?? []).compactMap { model in
                model["name"] as? String ?? model["model"] as? String
            }
        } else {
            names = (root["data"] as? [[String: Any]] ?? []).compactMap { model in
                model["id"] as? String
            }
        }
        let result = Array(Set(names.filter { !$0.isEmpty })).sorted()
        guard !result.isEmpty else { throw ProviderModelError.invalidResponse }
        return result
    }

    private func modelListRequest(configuration: AIConfiguration) throws -> URLRequest {
        let url: URL
        switch configuration.provider {
        case .apple:
            throw ProviderModelError.unsupported
        case .ollama:
            url = try endpoint(configuration.endpoint, path: "api/tags")
        case .openAI:
            url = try endpoint("https://api.openai.com/v1", path: "models")
        case .anthropic:
            url = try endpoint("https://api.anthropic.com/v1", path: "models")
        case .groq:
            url = try endpoint("https://api.groq.com/openai/v1", path: "models")
        case .openRouter:
            url = try endpoint("https://openrouter.ai/api/v1", path: "models")
        case .customOpenAI:
            url = try endpoint(configuration.endpoint, path: "models")
        }

        var request = URLRequest(url: url)
        if configuration.provider == .anthropic {
            guard !configuration.apiKey.isEmpty else { throw LanguageProviderError.missingAPIKey }
            request.setValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        } else if configuration.provider != .ollama, !configuration.apiKey.isEmpty {
            request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        } else if ![.ollama, .customOpenAI].contains(configuration.provider),
                  configuration.apiKey.isEmpty {
            throw LanguageProviderError.missingAPIKey
        }
        return request
    }

    private func endpoint(_ base: String, path: String) throws -> URL {
        guard let url = URL(string: base), url.scheme != nil else {
            throw ProviderModelError.invalidEndpoint
        }
        return url.appendingPathComponent(path)
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw ProviderModelError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ProviderModelError.requestFailed(
                response.statusCode,
                String(message.prefix(500))
            )
        }
        return data
    }
}
