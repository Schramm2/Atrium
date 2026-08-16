import Foundation

public enum GitHubSnapshotSection: String, Equatable, Sendable {
    case repositories
    case attention
    case recentDelivery
    case notifications
}

public struct GitHubSnapshotFailure: Equatable, Sendable {
    public let section: GitHubSnapshotSection
    public let message: String

    public init(section: GitHubSnapshotSection, message: String) {
        self.section = section
        self.message = message
    }
}

public struct GitHubRepositorySnapshot: Equatable, Sendable {
    public let repositories: [GitHubRepository]
    public let attention: [GitHubWorkItem]
    public let recentDelivery: [GitHubWorkItem]
    public let notifications: [GitHubNotification]
    public let failures: [GitHubSnapshotFailure]

    public init(
        repositories: [GitHubRepository],
        attention: [GitHubWorkItem],
        recentDelivery: [GitHubWorkItem],
        notifications: [GitHubNotification],
        failures: [GitHubSnapshotFailure] = []
    ) {
        self.repositories = repositories
        self.attention = attention
        self.recentDelivery = recentDelivery
        self.notifications = notifications
        self.failures = failures
    }
}
