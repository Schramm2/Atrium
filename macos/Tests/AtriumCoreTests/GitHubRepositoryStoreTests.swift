import Foundation
import Testing
@testable import AtriumCore

@Suite("GitHub repository preferences")
struct GitHubRepositoryStoreTests {
    @MainActor
    @Test("Successful loads stay fresh for five minutes")
    func freshness() async throws {
        let service = GitHubRepositoryService { arguments in
            .init(
                exitCode: 0,
                standardOutput: arguments.starts(with: ["gh", "api"]) ? "[]" : "[]",
                standardError: ""
            )
        }
        let store = GitHubRepositoryStore(service: service)

        await store.load()

        let updatedAt = try #require(store.lastUpdatedAt)
        #expect(!store.shouldRefresh(now: updatedAt.addingTimeInterval(299)))
        #expect(store.shouldRefresh(now: updatedAt.addingTimeInterval(300)))
    }

    @MainActor
    @Test("Failed loads remain eligible for retry")
    func failureRetries() async {
        let service = GitHubRepositoryService { _ in
            .init(exitCode: 1, standardOutput: "", standardError: "temporary failure")
        }
        let store = GitHubRepositoryStore(service: service)

        await store.load()

        #expect(store.hasLoaded)
        #expect(store.errorMessage != nil)
        #expect(store.shouldRefresh())
    }

    @MainActor
    @Test("Favourite repositories persist on this Mac")
    func favoritesPersist() throws {
        let suiteName = "GitHubRepositoryStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let repository = try JSONDecoder.github.decode(
            GitHubRepository.self,
            from: Data(Self.repositoryJSON.utf8)
        )

        let store = GitHubRepositoryStore(defaults: defaults)
        store.toggleFavorite(repository)

        #expect(store.isFavorite(repository))
        #expect(GitHubRepositoryStore(defaults: defaults).isFavorite(repository))

        store.toggleFavorite(repository)
        #expect(!GitHubRepositoryStore(defaults: defaults).isFavorite(repository))
    }

    private static let repositoryJSON = """
    {
      "id": 1,
      "name": "Atrium",
      "full_name": "Ubundi/Atrium",
      "description": "Company workspace",
      "private": true,
      "archived": false,
      "fork": false,
      "language": "Swift",
      "open_issues_count": 2,
      "default_branch": "main",
      "stargazers_count": 0,
      "updated_at": "2026-08-16T12:00:00Z",
      "html_url": "https://github.com/Ubundi/Atrium"
    }
    """
}

private extension JSONDecoder {
    static var github: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
