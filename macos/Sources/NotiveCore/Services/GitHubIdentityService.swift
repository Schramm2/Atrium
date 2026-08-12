import Foundation

public struct GitHubIdentity: Equatable, Sendable {
    public let login: String
    public let name: String?
    public let organizations: [String]

    public init(login: String, name: String?, organizations: [String]) {
        self.login = login
        self.name = name
        self.organizations = organizations
    }
}

public enum GitHubIdentityStatus: Equatable, Sendable {
    case cliMissing
    case notAuthenticated
    case notMember(GitHubIdentity)
    case verified(GitHubIdentity, organization: String)
}

/// Verifies the machine's authenticated GitHub CLI identity and its
/// membership in one of the company organizations.
public struct GitHubIdentityService: Sendable {
    public static let companyOrganizations = ["Ubundi", "first-motive"]

    public typealias Run = GitHubReleaseUpdater.Run

    private let run: Run

    public init(run: @escaping Run) {
        self.run = run
    }

    public static func live() -> Self {
        Self(run: GitHubReleaseUpdater.execute)
    }

    public func verify() -> GitHubIdentityStatus {
        guard run(["gh", "--version"]).succeeded else { return .cliMissing }

        let user = run([
            "gh", "api", "user",
            "--jq", "[.login, .name // \"\"] | @tsv",
        ])
        guard user.succeeded else { return .notAuthenticated }
        let fields = user.trimmedOutput.split(separator: "\t", omittingEmptySubsequences: false)
        guard let login = fields.first.map(String.init), !login.isEmpty else {
            return .notAuthenticated
        }
        let name = fields.dropFirst().first
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .flatMap { $0.isEmpty ? nil : $0 }

        let organizations = memberOrganizations()
        let identity = GitHubIdentity(login: login, name: name, organizations: organizations)
        guard let organization = Self.companyOrganization(among: organizations) else {
            return .notMember(identity)
        }
        return .verified(identity, organization: organization)
    }

    public static func companyOrganization(among organizations: [String]) -> String? {
        organizations.first { candidate in
            companyOrganizations.contains { $0.caseInsensitiveCompare(candidate) == .orderedSame }
        }
    }

    private func memberOrganizations() -> [String] {
        let result = run(["gh", "api", "user/orgs", "--paginate", "--jq", ".[].login"])
        guard result.succeeded else { return [] }
        return result.trimmedOutput
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
