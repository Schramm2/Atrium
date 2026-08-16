import Foundation
import Observation

@MainActor
@Observable
public final class GitHubRepositoryStore {
    public private(set) var repositories: [GitHubRepository] = []
    public private(set) var attention: [GitHubWorkItem] = []
    public private(set) var recentDelivery: [GitHubWorkItem] = []
    public private(set) var notifications: [GitHubNotification] = []
    public private(set) var sectionFailures: [GitHubSnapshotFailure] = []
    public private(set) var favoriteFullNames: Set<String>
    public private(set) var isLoading = false
    public private(set) var hasLoaded = false
    public private(set) var lastUpdatedAt: Date?
    public private(set) var errorMessage: String?

    @ObservationIgnored private let service: GitHubRepositoryService
    @ObservationIgnored private let defaults: UserDefaults
    private static let favoritesKey = "atrium.github.favorite-repositories"

    public init(
        service: GitHubRepositoryService = .live(),
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.defaults = defaults
        favoriteFullNames = Set(defaults.stringArray(forKey: Self.favoritesKey) ?? [])
    }

    public var favoriteRepositories: [GitHubRepository] {
        repositories.filter { favoriteFullNames.contains($0.fullName) }
    }

    public func isFavorite(_ repository: GitHubRepository) -> Bool {
        favoriteFullNames.contains(repository.fullName)
    }

    public func toggleFavorite(_ repository: GitHubRepository) {
        if !favoriteFullNames.insert(repository.fullName).inserted {
            favoriteFullNames.remove(repository.fullName)
        }
        defaults.set(favoriteFullNames.sorted(), forKey: Self.favoritesKey)
    }

    public func failureMessage(for section: GitHubSnapshotSection) -> String? {
        sectionFailures.first { $0.section == section }?.message
    }

    public func shouldRefresh(now: Date = .now) -> Bool {
        guard errorMessage == nil, sectionFailures.isEmpty, let lastUpdatedAt else { return true }
        return now.timeIntervalSince(lastUpdatedAt) >= 5 * 60
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await service.loadSnapshot()
            repositories = snapshot.repositories
            attention = snapshot.attention
            recentDelivery = snapshot.recentDelivery
            notifications = snapshot.notifications
            sectionFailures = snapshot.failures
            errorMessage = nil
            hasLoaded = true
            lastUpdatedAt = .now
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            hasLoaded = true
            DiagnosticLogger.failure(operation: "github_repositories_load", error: error)
        }
    }
}
