import Foundation

public struct GitHubWorkflowRun: Decodable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String?
    public let status: String
    public let conclusion: String?
    public let url: URL
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion
        case url = "html_url"
        case updatedAt = "updated_at"
    }
}
