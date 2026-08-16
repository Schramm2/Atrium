import Foundation

public struct GitHubRepositoryDetail: Equatable, Sendable {
    public let openPullRequests: [GitHubRepositoryDetailItem]
    public let recentIssues: [GitHubRepositoryDetailItem]
    public let latestRelease: GitHubReleaseSummary?
    public let latestWorkflowRun: GitHubWorkflowRun?

    public init(
        openPullRequests: [GitHubRepositoryDetailItem],
        recentIssues: [GitHubRepositoryDetailItem],
        latestRelease: GitHubReleaseSummary?,
        latestWorkflowRun: GitHubWorkflowRun?
    ) {
        self.openPullRequests = openPullRequests
        self.recentIssues = recentIssues
        self.latestRelease = latestRelease
        self.latestWorkflowRun = latestWorkflowRun
    }
}
