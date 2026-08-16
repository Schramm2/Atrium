import Foundation

struct GitHubSearchResult: Decodable, Sendable {
    struct Author: Decodable, Sendable {
        let login: String
    }

    struct Label: Decodable, Sendable {
        let name: String
    }

    let number: Int
    let title: String
    let url: URL
    let updatedAt: Date
    let repository: [String: String]
    let author: Author?
    let labels: [Label]
    let state: String
    let commentsCount: Int

    func workItem(kind: GitHubWorkItemKind) -> GitHubWorkItem? {
        guard let repositoryFullName = repository["nameWithOwner"] else { return nil }
        return GitHubWorkItem(
            kind: kind,
            repositoryFullName: repositoryFullName,
            title: title,
            number: number,
            url: url,
            updatedAt: updatedAt,
            authorLogin: author?.login,
            labelNames: labels.map(\.name),
            state: state,
            commentsCount: commentsCount
        )
    }
}
