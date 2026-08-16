import Foundation

public struct GitHubRepositoryDetailItem: Decodable, Equatable, Identifiable, Sendable {
    public let number: Int
    public let title: String
    public let url: URL
    public let updatedAt: Date
    public let isDraft: Bool?

    public var id: URL { url }

    private enum CodingKeys: String, CodingKey {
        case number, title, draft
        case url = "html_url"
        case updatedAt = "updated_at"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        number = try values.decode(Int.self, forKey: .number)
        title = try values.decode(String.self, forKey: .title)
        url = try values.decode(URL.self, forKey: .url)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
        isDraft = try values.decodeIfPresent(Bool.self, forKey: .draft)
    }
}
