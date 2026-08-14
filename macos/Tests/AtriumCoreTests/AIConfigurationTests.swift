@testable import AtriumCore
import Foundation
import Testing

@Suite("AI configuration boundaries")
struct AIConfigurationTests {
    @Test("Loopback model endpoints stay local")
    func loopback() {
        #expect(!AIConfiguration(provider: .ollama, model: "model", endpoint: "http://localhost:11434").isExternal)
        #expect(!AIConfiguration(provider: .customOpenAI, model: "model", endpoint: "http://127.0.0.1:8178/v1").isExternal)
        #expect(AIConfiguration(provider: .ollama, model: "model", endpoint: "https://models.example.com").isExternal)
    }

    @Test("External evidence confirmation applies once per provider and session")
    func remote() {
        let openAI = AIConfiguration(provider: .openAI, model: "model")
        let anthropic = AIConfiguration(provider: .anthropic, model: "model")
        let apple = AIConfiguration(provider: .apple, model: "on-device")

        #expect(openAI.needsExternalEvidenceConfirmation(confirmedProviders: []))
        #expect(!openAI.needsExternalEvidenceConfirmation(confirmedProviders: [.openAI]))
        #expect(anthropic.needsExternalEvidenceConfirmation(confirmedProviders: [.openAI]))
        #expect(!apple.needsExternalEvidenceConfirmation(confirmedProviders: []))
    }

    @Test("Non-secret configuration loads from isolated defaults")
    func defaults() throws {
        let name = "atrium-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("ollama", forKey: "notive.ai.provider")
        defaults.set("qwen", forKey: "notive.ai.model")
        defaults.set("http://localhost:11434", forKey: "notive.ai.endpoint")

        let configuration = AIConfiguration.load(defaults: defaults)

        #expect(configuration.provider == .ollama)
        #expect(configuration.model == "qwen")
        #expect(!configuration.isExternal)
    }

    @Test("Provider model lists normalize Ollama and API responses")
    func providerModelLists() throws {
        let ollama = Data(#"{"models":[{"name":"qwen:4b"},{"model":"llama:3b"},{"name":"qwen:4b"}]}"#.utf8)
        let remote = Data(#"{"data":[{"id":"model-b"},{"id":"model-a"}]}"#.utf8)

        #expect(
            try ProviderModelService.modelNames(from: ollama, provider: .ollama)
                == ["llama:3b", "qwen:4b"]
        )
        #expect(
            try ProviderModelService.modelNames(from: remote, provider: .openAI)
                == ["model-a", "model-b"]
        )
    }
}
