import AtriumCore

extension GitHubWorkItemKind {
    var title: String {
        switch self {
        case .reviewRequested: "Review requested"
        case .changesRequested: "Changes requested"
        case .approvedToMerge: "Ready to merge"
        case .failedChecks: "Checks failed"
        case .assignedIssue: "Assigned to you"
        case .stalePullRequest: "Stale pull request"
        case .mergedPullRequest: "Merged"
        }
    }

    var systemImage: String {
        switch self {
        case .reviewRequested: "person.crop.circle.badge.checkmark"
        case .changesRequested: "arrow.uturn.backward.circle"
        case .approvedToMerge: "checkmark.circle"
        case .failedChecks: "xmark.circle"
        case .assignedIssue: "person.crop.circle"
        case .stalePullRequest: "clock.badge.exclamationmark"
        case .mergedPullRequest: "arrow.triangle.merge"
        }
    }
}
