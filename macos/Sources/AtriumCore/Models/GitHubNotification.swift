import Foundation

public struct GitHubNotification: Decodable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let type: String
    public let reason: String
    public let repositoryFullName: String
    public let url: URL
    public let updatedAt: Date

    public var reasonTitle: String {
        switch reason {
        case "assign": "Assigned"
        case "author": "Your thread"
        case "ci_activity": "Workflow update"
        case "comment": "New comment"
        case "invitation": "Invitation"
        case "manual": "Subscribed"
        case "mention": "Mentioned"
        case "review_requested": "Review requested"
        case "security_alert": "Security alert"
        case "state_change": "State changed"
        case "subscribed": "Watching"
        case "team_mention": "Team mentioned"
        default: reason.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private struct Subject: Decodable {
        let title: String
        let url: URL?
        let type: String
    }

    private struct Repository: Decodable {
        let fullName: String
        let url: URL

        private enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case url = "html_url"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, reason, subject, repository
        case updatedAt = "updated_at"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let subject = try values.decode(Subject.self, forKey: .subject)
        let repository = try values.decode(Repository.self, forKey: .repository)
        id = try values.decode(String.self, forKey: .id)
        title = subject.title
        type = subject.type
        reason = try values.decode(String.self, forKey: .reason)
        repositoryFullName = repository.fullName
        url = Self.browserURL(for: subject.url, repositoryURL: repository.url)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
    }

    private static func browserURL(for apiURL: URL?, repositoryURL: URL) -> URL {
        guard let apiURL, apiURL.host == "api.github.com" else { return repositoryURL }
        let parts = apiURL.pathComponents.filter { $0 != "/" }
        guard parts.count >= 5, parts[0] == "repos" else { return repositoryURL }
        var resource = Array(parts.dropFirst(3))
        if resource[0] == "pulls" { resource[0] = "pull" }
        if resource[0] == "commits" { resource[0] = "commit" }
        if resource[0] == "releases" { return repositoryURL.appending(path: "releases") }
        return resource.reduce(repositoryURL) { $0.appending(path: $1) }
    }
}
