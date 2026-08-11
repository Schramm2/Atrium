import Foundation
import Security

public enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    case apple = "apple"
    case ollama = "ollama"
    case openAI = "openai"
    case anthropic = "anthropic"
    case groq = "groq"
    case openRouter = "openrouter"
    case customOpenAI = "custom-openai"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .apple: "Apple Intelligence"
        case .ollama: "Ollama"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .groq: "Groq"
        case .openRouter: "OpenRouter"
        case .customOpenAI: "OpenAI-compatible"
        }
    }
}

public struct AIConfiguration: Equatable, Sendable {
    public var provider: AIProvider
    public var model: String
    public var endpoint: String
    public var apiKey: String

    public init(provider: AIProvider, model: String, endpoint: String = "", apiKey: String = "") {
        self.provider = provider
        self.model = model
        self.endpoint = endpoint
        self.apiKey = apiKey
    }

    public var isExternal: Bool {
        switch provider {
        case .apple:
            return false
        case .ollama, .customOpenAI:
            guard let host = URL(string: endpoint)?.host?.lowercased() else { return provider != .ollama }
            return !["localhost", "127.0.0.1", "::1"].contains(host)
        default:
            return true
        }
    }

    public func needsExternalEvidenceConfirmation(
        confirmedProviders: Set<AIProvider>
    ) -> Bool {
        isExternal && !confirmedProviders.contains(provider)
    }

    public static func load(defaults: UserDefaults = .standard) -> AIConfiguration {
        let provider = AIProvider(rawValue: defaults.string(forKey: "notive.ai.provider") ?? "apple") ?? .apple
        let model = defaults.string(forKey: "notive.ai.model") ?? defaultModel(for: provider)
        let endpoint = defaults.string(forKey: "notive.ai.endpoint") ?? defaultEndpoint(for: provider)
        let apiKey = SecureValueStore.read(account: provider.rawValue) ?? ""
        return AIConfiguration(provider: provider, model: model, endpoint: endpoint, apiKey: apiKey)
    }

    public func save(defaults: UserDefaults = .standard) throws {
        try SecureValueStore.write(apiKey, account: provider.rawValue)
        defaults.set(provider.rawValue, forKey: "notive.ai.provider")
        defaults.set(model, forKey: "notive.ai.model")
        defaults.set(endpoint, forKey: "notive.ai.endpoint")
    }

    public static func defaultModel(for provider: AIProvider) -> String {
        switch provider {
        case .apple: "on-device"
        case .ollama: "qwen3.5:4b"
        case .openAI: "gpt-4.1-mini"
        case .anthropic: "claude-sonnet-4-5"
        case .groq: "llama-3.3-70b-versatile"
        case .openRouter: "openai/gpt-4.1-mini"
        case .customOpenAI: "default"
        }
    }

    public static func defaultEndpoint(for provider: AIProvider) -> String {
        switch provider {
        case .ollama: "http://localhost:11434"
        case .customOpenAI: "http://localhost:11434/v1"
        default: ""
        }
    }
}

private enum SecureValueStore {
    private static let service = "com.ubundi.meet.ai"

    static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(_ value: String, account: String) throws {
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        guard !value.isEmpty else {
            let status = SecItemDelete(identity as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw DatabaseError.invalidData("Notive could not remove the API key from Keychain.")
            }
            return
        }

        let attributes = [kSecValueData as String: Data(value.utf8)]
        let updateStatus = SecItemUpdate(identity as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }

        guard updateStatus == errSecItemNotFound else {
            throw DatabaseError.invalidData("Notive could not save the API key in Keychain.")
        }
        var item = identity
        item[kSecValueData as String] = Data(value.utf8)
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
            throw DatabaseError.invalidData("Notive could not save the API key in Keychain.")
        }
    }
}
