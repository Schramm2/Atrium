import Foundation
import Observation

@MainActor
@Observable
public final class GitHubRepositoryDetailStore {
    public private(set) var detail: GitHubRepositoryDetail?
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    public let repository: GitHubRepository
    @ObservationIgnored private let service: GitHubRepositoryService

    public init(
        repository: GitHubRepository,
        service: GitHubRepositoryService = .live()
    ) {
        self.repository = repository
        self.service = service
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await service.loadDetail(for: repository)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            DiagnosticLogger.failure(operation: "github_repository_detail_load", error: error)
        }
    }
}
