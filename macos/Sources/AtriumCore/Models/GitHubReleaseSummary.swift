import Foundation

public struct GitHubReleaseSummary: Decodable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String?
    public let tagName: String
    public let url: URL
    public let publishedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, name
        case tagName = "tag_name"
        case url = "html_url"
        case publishedAt = "published_at"
    }
}
