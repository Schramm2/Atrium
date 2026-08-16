import Foundation

public struct GitHubWorkItem: Equatable, Identifiable, Sendable {
    public let kind: GitHubWorkItemKind
    public let repositoryFullName: String
    public let title: String
    public let number: Int
    public let url: URL
    public let updatedAt: Date
    public let authorLogin: String?
    public let labelNames: [String]
    public let state: String
    public let commentsCount: Int

    public var id: String { "\(kind.rawValue):\(url.absoluteString)" }

    public init(
        kind: GitHubWorkItemKind,
        repositoryFullName: String,
        title: String,
        number: Int,
        url: URL,
        updatedAt: Date,
        authorLogin: String? = nil,
        labelNames: [String] = [],
        state: String = "open",
        commentsCount: Int = 0
    ) {
        self.kind = kind
        self.repositoryFullName = repositoryFullName
        self.title = title
        self.number = number
        self.url = url
        self.updatedAt = updatedAt
        self.authorLogin = authorLogin
        self.labelNames = labelNames
        self.state = state
        self.commentsCount = commentsCount
    }
}
