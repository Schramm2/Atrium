import Foundation

struct GitHubWorkflowRunsResponse: Decodable, Sendable {
    let workflowRuns: [GitHubWorkflowRun]

    private enum CodingKeys: String, CodingKey {
        case workflowRuns = "workflow_runs"
    }
}
