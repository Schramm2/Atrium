import Foundation
import Testing
@testable import AtriumCore

@Suite("GitHub repository loading")
struct GitHubRepositoryServiceTests {
    @Test("Repositories from both organizations are merged and sorted by recent work")
    func loadsBothOrganizations() async throws {
        let service = GitHubRepositoryService { arguments in
            let organization = arguments.joined(separator: " ").contains("first-motive")
                ? "first-motive"
                : "Ubundi"
            let updatedAt = organization == "first-motive"
                ? "2026-08-16T12:00:00Z"
                : "2026-08-15T12:00:00Z"
            return .init(
                exitCode: 0,
                standardOutput: "[[{\"id\":1,\"name\":\"repo\",\"full_name\":\"\(organization)/repo\",\"description\":\"Useful work\",\"private\":true,\"archived\":false,\"fork\":false,\"language\":\"Swift\",\"open_issues_count\":2,\"default_branch\":\"main\",\"stargazers_count\":3,\"updated_at\":\"\(updatedAt)\",\"html_url\":\"https://github.com/\(organization)/repo\"}]]",
                standardError: ""
            )
        }

        let repositories = try await service.loadRepositories()

        #expect(repositories.map(\.organization) == ["first-motive", "Ubundi"])
        #expect(repositories.first?.organizationTitle == "First Motive")
        #expect(repositories.allSatisfy { $0.isPrivate })
    }

    @Test("A snapshot separates action items from recent delivery")
    func loadsActionableWork() async throws {
        let service = GitHubRepositoryService { arguments in
            if arguments.starts(with: ["gh", "api"]) {
                return .init(exitCode: 0, standardOutput: "[]", standardError: "")
            }

            let kind: String
            if arguments.contains("changes_requested") {
                kind = "changes"
            } else if arguments.contains("approved") {
                kind = "approved"
            } else if arguments.contains("--review-requested") {
                kind = "review"
            } else if arguments.contains("--checks") {
                kind = "failure"
            } else if arguments.contains("--assignee") {
                kind = "assignment"
            } else if arguments.contains("--updated") {
                kind = "stale"
            } else {
                kind = "merged"
            }
            let hour = [
                "changes": 14, "approved": 13, "failure": 12, "assignment": 11,
                "review": 10, "stale": 9, "merged": 8,
            ][kind] ?? 0
            return .init(
                exitCode: 0,
                standardOutput: "[{\"number\":1,\"title\":\"\(kind) work\",\"url\":\"https://github.com/Ubundi/repo/pull/\(kind)\",\"updatedAt\":\"2026-08-16T\(hour):00:00Z\",\"repository\":{\"nameWithOwner\":\"Ubundi/repo\"},\"author\":{\"login\":\"octocat\"},\"labels\":[{\"name\":\"priority\"}],\"state\":\"open\",\"commentsCount\":2}]",
                standardError: ""
            )
        }

        let snapshot = try await service.loadSnapshot(
            now: try #require(ISO8601DateFormatter().date(from: "2026-08-16T12:00:00Z"))
        )

        #expect(snapshot.attention.map(\.kind) == [
            .changesRequested, .approvedToMerge, .failedChecks, .assignedIssue,
            .reviewRequested, .stalePullRequest,
        ])
        #expect(snapshot.attention.first?.authorLogin == "octocat")
        #expect(snapshot.attention.first?.labelNames == ["priority"])
        #expect(snapshot.recentDelivery.map(\.kind) == [.mergedPullRequest])
    }

    @Test("One failed search preserves the other snapshot sections")
    func preservesPartialResults() async throws {
        let service = GitHubRepositoryService { arguments in
            if arguments.contains("changes_requested") {
                return .init(exitCode: 1, standardOutput: "", standardError: "temporary search failure")
            }
            if arguments.contains("/notifications?all=false&participating=false&per_page=50") {
                return .init(exitCode: 0, standardOutput: Self.notificationsJSON, standardError: "")
            }
            return .init(exitCode: 0, standardOutput: "[]", standardError: "")
        }

        let snapshot = try await service.loadSnapshot()

        #expect(snapshot.failures.map(\.section) == [.attention])
        #expect(snapshot.notifications.count == 1)
        #expect(snapshot.notifications.first?.reasonTitle == "Review requested")
        #expect(snapshot.notifications.first?.url.absoluteString == "https://github.com/Ubundi/repo/pull/7")
    }

    @Test("Repository detail caches calls and scopes workflow health to the default branch")
    func loadsRepositoryDetail() async throws {
        let service = GitHubRepositoryService { arguments in
            guard arguments.contains("--cache"), arguments.contains("300s") else {
                return .init(exitCode: 1, standardOutput: "", standardError: "missing cache")
            }
            let endpoint = arguments.dropFirst(2).first ?? ""
            if endpoint.contains("/pulls?") {
                return .init(exitCode: 0, standardOutput: Self.detailItemJSON, standardError: "")
            }
            if endpoint.contains("/issues?") {
                return .init(exitCode: 0, standardOutput: Self.detailItemJSON, standardError: "")
            }
            if endpoint.contains("/releases/latest") {
                return .init(exitCode: 0, standardOutput: Self.releaseJSON, standardError: "")
            }
            guard endpoint.contains("branch=main") else {
                return .init(exitCode: 1, standardOutput: "", standardError: "missing default branch")
            }
            return .init(exitCode: 0, standardOutput: Self.workflowJSON, standardError: "")
        }
        let repository = try JSONDecoder.github.decode(
            GitHubRepository.self,
            from: Data(Self.repositoryJSON.utf8)
        )

        let detail = try await service.loadDetail(for: repository)

        #expect(detail.openPullRequests.count == 1)
        #expect(detail.recentIssues.count == 1)
        #expect(detail.latestRelease?.tagName == "v1.0.0")
        #expect(detail.latestWorkflowRun?.conclusion == "success")
    }

    @Test("A GitHub CLI failure gives a useful recovery message")
    func commandFailure() async {
        let service = GitHubRepositoryService { _ in
            .init(exitCode: 1, standardOutput: "", standardError: "authentication required")
        }

        do {
            _ = try await service.loadRepositories()
            Issue.record("Expected repository loading to fail")
        } catch let error as GitHubRepositoryService.RepositoryError {
            #expect(error.errorDescription?.contains("authentication required") == true)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private static let repositoryJSON = """
    {"id":1,"name":"repo","full_name":"Ubundi/repo","private":true,"archived":false,"fork":false,"language":"Swift","open_issues_count":2,"default_branch":"main","updated_at":"2026-08-16T12:00:00Z","html_url":"https://github.com/Ubundi/repo"}
    """
    private static let detailItemJSON = """
    [{"number":2,"title":"Work","html_url":"https://github.com/Ubundi/repo/pull/2","updated_at":"2026-08-16T12:00:00Z","draft":false}]
    """
    private static let releaseJSON = """
    {"id":3,"name":"One","tag_name":"v1.0.0","html_url":"https://github.com/Ubundi/repo/releases/v1.0.0","published_at":"2026-08-16T12:00:00Z"}
    """
    private static let workflowJSON = """
    {"workflow_runs":[{"id":4,"name":"CI","status":"completed","conclusion":"success","html_url":"https://github.com/Ubundi/repo/actions/runs/4","updated_at":"2026-08-16T12:00:00Z"}]}
    """
    private static let notificationsJSON = """
    [[{"id":"1","reason":"review_requested","updated_at":"2026-08-16T12:00:00Z","subject":{"title":"Review this","url":"https://api.github.com/repos/Ubundi/repo/pulls/7","type":"PullRequest"},"repository":{"full_name":"Ubundi/repo","html_url":"https://github.com/Ubundi/repo"}}]]
    """
}

private extension JSONDecoder {
    static var github: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
