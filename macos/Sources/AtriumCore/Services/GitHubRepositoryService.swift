import Foundation

public struct GitHubRepositoryService: Sendable {
    public enum RepositoryError: LocalizedError, Equatable, Sendable {
        case commandFailed(String)
        case invalidResponse

        public var errorDescription: String? {
            switch self {
            case let .commandFailed(reason):
                "GitHub could not load company work. \(reason)"
            case .invalidResponse:
                "GitHub returned data that Atrium could not read. Try refreshing."
            }
        }
    }

    public typealias Run = GitHubCommandExecutor.Run

    private let run: Run

    public init(run: @escaping Run) {
        self.run = run
    }

    public static func live() -> Self {
        Self(run: GitHubCommandExecutor.execute)
    }

    public func loadSnapshot(now: Date = .now) async throws -> GitHubRepositorySnapshot {
        let staleDate = Self.dateString(now.addingTimeInterval(-7 * 24 * 60 * 60))
        let recentDate = Self.dateString(now.addingTimeInterval(-14 * 24 * 60 * 60))

        async let repositories = capture { try await loadRepositories() }
        async let reviews = capture {
            try await search(
                command: "prs",
                kind: .reviewRequested,
                filters: ["--review-requested", "@me", "--state", "open", "--sort", "updated"]
            )
        }
        async let changesRequested = capture {
            try await search(
                command: "prs",
                kind: .changesRequested,
                filters: ["--review", "changes_requested", "--author", "@me", "--state", "open", "--sort", "updated"]
            )
        }
        async let approved = capture {
            try await search(
                command: "prs",
                kind: .approvedToMerge,
                filters: ["--review", "approved", "--author", "@me", "--state", "open", "--sort", "updated"]
            )
        }
        async let failedChecks = capture {
            try await search(
                command: "prs",
                kind: .failedChecks,
                filters: ["--checks", "failure", "--state", "open", "--sort", "updated"]
            )
        }
        async let assignments = capture {
            try await search(
                command: "issues",
                kind: .assignedIssue,
                filters: ["--assignee", "@me", "--state", "open", "--sort", "updated"]
            )
        }
        async let stale = capture {
            try await search(
                command: "prs",
                kind: .stalePullRequest,
                filters: ["--involves", "@me", "--state", "open", "--updated", "<=\(staleDate)", "--sort", "updated"]
            )
        }
        async let merged = capture {
            try await search(
                command: "prs",
                kind: .mergedPullRequest,
                filters: ["--merged", "--merged-at", ">=\(recentDate)", "--sort", "updated"]
            )
        }
        async let notifications = capture { try await loadNotifications() }

        let loaded = await (
            repositories,
            reviews,
            changesRequested,
            approved,
            failedChecks,
            assignments,
            stale,
            merged,
            notifications
        )
        if loaded.0.isCancelled || loaded.1.isCancelled || loaded.2.isCancelled
            || loaded.3.isCancelled || loaded.4.isCancelled || loaded.5.isCancelled
            || loaded.6.isCancelled || loaded.7.isCancelled || loaded.8.isCancelled {
            throw CancellationError()
        }

        var failures: [GitHubSnapshotFailure] = []
        let repositoryItems = Self.value(loaded.0, section: .repositories, failures: &failures) ?? []
        let reviewItems = Self.value(loaded.1, section: .attention, failures: &failures) ?? []
        let changeItems = Self.value(loaded.2, section: .attention, failures: &failures) ?? []
        let approvedItems = Self.value(loaded.3, section: .attention, failures: &failures) ?? []
        let failedItems = Self.value(loaded.4, section: .attention, failures: &failures) ?? []
        let assignedItems = Self.value(loaded.5, section: .attention, failures: &failures) ?? []
        let staleItems = Self.value(loaded.6, section: .attention, failures: &failures) ?? []
        let deliveryItems = Self.value(loaded.7, section: .recentDelivery, failures: &failures) ?? []
        let notificationItems = Self.value(loaded.8, section: .notifications, failures: &failures) ?? []

        if failures.count == 9 {
            throw RepositoryError.commandFailed("Every GitHub section failed. \(failures[0].message)")
        }

        return GitHubRepositorySnapshot(
            repositories: repositoryItems,
            attention: Self.unique(changeItems + approvedItems + reviewItems + failedItems + assignedItems + staleItems),
            recentDelivery: deliveryItems,
            notifications: notificationItems,
            failures: Self.uniqueFailures(failures)
        )
    }

    public func loadRepositories() async throws -> [GitHubRepository] {
        let repositories = try await withThrowingTaskGroup(of: [GitHubRepository].self) { group in
            for organization in GitHubIdentityService.companyOrganizations {
                group.addTask { try await loadOrganization(organization) }
            }
            var repositories: [GitHubRepository] = []
            for try await organizationRepositories in group {
                repositories += organizationRepositories
            }
            return repositories
        }
        return repositories.sorted {
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending
        }
    }

    public func loadDetail(for repository: GitHubRepository) async throws -> GitHubRepositoryDetail {
        let base = "/repos/\(repository.fullName)"
        let branch = repository.defaultBranch.addingPercentEncoding(withAllowedCharacters: Self.queryValueCharacters)
            ?? repository.defaultBranch
        async let pullRequests = loadDetailItems(
            endpoint: "\(base)/pulls?state=open&sort=updated&direction=desc&per_page=10"
        )
        async let issues = loadDetailItems(
            endpoint: "\(base)/issues?state=open&sort=updated&direction=desc&per_page=10",
            jq: "[.[] | select(.pull_request == null)]"
        )
        async let release = loadLatestRelease(endpoint: "\(base)/releases/latest")
        async let workflow = loadLatestWorkflowRun(
            endpoint: "\(base)/actions/runs?branch=\(branch)&per_page=1"
        )
        return try await GitHubRepositoryDetail(
            openPullRequests: pullRequests,
            recentIssues: issues,
            latestRelease: release,
            latestWorkflowRun: workflow
        )
    }

    private func loadOrganization(_ organization: String) async throws -> [GitHubRepository] {
        let result = await execute([
            "gh", "api", "--paginate",
            "/orgs/\(organization)/repos?per_page=100&type=all&sort=updated",
            "--slurp",
        ])
        try Task.checkCancellation()
        guard result.succeeded else { throw commandError(result) }

        let decoder = Self.decoder
        guard let pages = try? decoder.decode([[GitHubRepository]].self, from: Data(result.standardOutput.utf8)) else {
            throw RepositoryError.invalidResponse
        }
        return pages.flatMap { $0 }
    }

    private func search(
        command: String,
        kind: GitHubWorkItemKind,
        filters: [String]
    ) async throws -> [GitHubWorkItem] {
        let owners = GitHubIdentityService.companyOrganizations.flatMap { ["--owner", $0] }
        let result = await execute([
            "gh", "search", command,
        ] + owners + filters + [
            "--archived=false",
            "--limit", "20",
            "--json", "number,title,url,updatedAt,repository,author,labels,state,commentsCount",
        ])
        try Task.checkCancellation()
        guard result.succeeded else { throw commandError(result) }

        guard let results = try? Self.decoder.decode(
            [GitHubSearchResult].self,
            from: Data(result.standardOutput.utf8)
        ) else { throw RepositoryError.invalidResponse }
        return results.compactMap { $0.workItem(kind: kind) }
    }

    private func loadNotifications() async throws -> [GitHubNotification] {
        let result = await execute([
            "gh", "api", "--paginate", "/notifications?all=false&participating=false&per_page=50",
            "--slurp", "--cache", "300s",
        ])
        try Task.checkCancellation()
        guard result.succeeded else { throw commandError(result) }
        guard let pages = try? Self.decoder.decode(
            [[GitHubNotification]].self,
            from: Data(result.standardOutput.utf8)
        ) else { throw RepositoryError.invalidResponse }
        return pages.flatMap { $0 }.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func loadDetailItems(
        endpoint: String,
        jq: String? = nil
    ) async throws -> [GitHubRepositoryDetailItem] {
        var arguments = ["gh", "api", endpoint, "--cache", "300s"]
        if let jq { arguments += ["--jq", jq] }
        let result = await execute(arguments)
        try Task.checkCancellation()
        guard result.succeeded else { throw commandError(result) }
        guard let items = try? Self.decoder.decode(
            [GitHubRepositoryDetailItem].self,
            from: Data(result.standardOutput.utf8)
        ) else { throw RepositoryError.invalidResponse }
        return items
    }

    private func loadLatestRelease(endpoint: String) async throws -> GitHubReleaseSummary? {
        let result = await execute(["gh", "api", endpoint, "--cache", "300s"])
        try Task.checkCancellation()
        guard result.succeeded else { return nil }
        guard let release = try? Self.decoder.decode(
            GitHubReleaseSummary.self,
            from: Data(result.standardOutput.utf8)
        ) else { throw RepositoryError.invalidResponse }
        return release
    }

    private func loadLatestWorkflowRun(endpoint: String) async throws -> GitHubWorkflowRun? {
        let result = await execute(["gh", "api", endpoint, "--cache", "300s"])
        try Task.checkCancellation()
        guard result.succeeded else { return nil }
        guard let response = try? Self.decoder.decode(
            GitHubWorkflowRunsResponse.self,
            from: Data(result.standardOutput.utf8)
        ) else { throw RepositoryError.invalidResponse }
        return response.workflowRuns.first
    }

    private func capture<Value: Sendable>(
        _ operation: @Sendable () async throws -> Value
    ) async -> LoadResult<Value> {
        do {
            return .success(try await operation())
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .failure((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    private func execute(_ arguments: [String]) async -> GitHubReleaseUpdater.CommandResult {
        await run(arguments)
    }

    private func commandError(_ result: GitHubReleaseUpdater.CommandResult) -> RepositoryError {
        let error = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = error.isEmpty ? "Check your GitHub CLI sign-in and organization access." : error
        return .commandFailed(reason)
    }

    private static func value<Value: Sendable>(
        _ result: LoadResult<Value>,
        section: GitHubSnapshotSection,
        failures: inout [GitHubSnapshotFailure]
    ) -> Value? {
        switch result {
        case let .success(value): return value
        case let .failure(message):
            failures.append(.init(section: section, message: message))
            return nil
        case .cancelled: return nil
        }
    }

    private static func unique(_ items: [GitHubWorkItem]) -> [GitHubWorkItem] {
        var seen = Set<URL>()
        return items
            .filter { seen.insert($0.url).inserted }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private static func uniqueFailures(_ failures: [GitHubSnapshotFailure]) -> [GitHubSnapshotFailure] {
        var seen = Set<GitHubSnapshotSection>()
        return failures.filter { seen.insert($0.section).inserted }
    }

    private static func dateString(_ date: Date) -> String {
        let parts = Calendar(identifier: .gregorian).dateComponents(in: .gmt, from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static let queryValueCharacters = CharacterSet.urlQueryAllowed
        .subtracting(CharacterSet(charactersIn: "&=+"))
}

private enum LoadResult<Value: Sendable>: Sendable {
    case success(Value)
    case failure(String)
    case cancelled

    var isCancelled: Bool {
        if case .cancelled = self { return true }
        return false
    }
}
