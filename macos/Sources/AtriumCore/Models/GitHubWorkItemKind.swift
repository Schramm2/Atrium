import Foundation

public enum GitHubWorkItemKind: String, Decodable, Equatable, Sendable {
    case reviewRequested
    case changesRequested
    case approvedToMerge
    case failedChecks
    case assignedIssue
    case stalePullRequest
    case mergedPullRequest
}
