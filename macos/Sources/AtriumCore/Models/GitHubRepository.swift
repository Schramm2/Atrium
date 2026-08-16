import Foundation

public struct GitHubRepository: Decodable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let fullName: String
    public let description: String?
    public let isPrivate: Bool
    public let isArchived: Bool
    public let isFork: Bool
    public let language: String?
    public let openItemCount: Int
    public let defaultBranch: String
    public let updatedAt: Date
    public let url: URL

    public var organization: String {
        fullName.split(separator: "/", maxSplits: 1).first.map(String.init) ?? ""
    }

    public var organizationTitle: String {
        organization.caseInsensitiveCompare("first-motive") == .orderedSame
            ? "First Motive"
            : organization
    }

    public var languageTitle: String { language ?? "—" }
    public var visibilityTitle: String { isPrivate ? "Private" : "Public" }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, language, archived, fork
        case fullName = "full_name"
        case isPrivate = "private"
        case openItemCount = "open_issues_count"
        case defaultBranch = "default_branch"
        case updatedAt = "updated_at"
        case url = "html_url"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        fullName = try values.decode(String.self, forKey: .fullName)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        isPrivate = try values.decode(Bool.self, forKey: .isPrivate)
        isArchived = try values.decode(Bool.self, forKey: .archived)
        isFork = try values.decode(Bool.self, forKey: .fork)
        language = try values.decodeIfPresent(String.self, forKey: .language)
        openItemCount = try values.decode(Int.self, forKey: .openItemCount)
        defaultBranch = try values.decode(String.self, forKey: .defaultBranch)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
        url = try values.decode(URL.self, forKey: .url)
    }
}
