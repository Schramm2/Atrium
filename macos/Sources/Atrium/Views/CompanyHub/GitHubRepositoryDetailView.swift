import AtriumCore
import SwiftUI

struct GitHubRepositoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: GitHubRepositoryDetailStore

    init(repository: GitHubRepository) {
        _store = State(initialValue: GitHubRepositoryDetailStore(repository: repository))
    }

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AtriumPageHeader(
                        store.repository.fullName,
                        detail: store.repository.description ?? "Repository activity and delivery health."
                    ) {
                        Link("Open in GitHub", destination: store.repository.url)
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                    }

                    content
                }
                .padding(32)
                .frame(maxWidth: 960, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(minWidth: 760, minHeight: 600)
        .navigationTitle(store.repository.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: dismiss.callAsFunction)
            }
        }
        .task { await store.load() }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading, store.detail == nil {
            ProgressView("Loading repository…")
                .frame(maxWidth: .infinity, minHeight: 240)
        } else if let error = store.errorMessage, store.detail == nil {
            ContentUnavailableView(
                "Repository unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
            .frame(maxWidth: .infinity, minHeight: 240)
        } else if let detail = store.detail {
            deliveryStatus(detail)
            GitHubDetailItemList(
                title: "Open pull requests",
                emptyTitle: "No open pull requests",
                systemImage: "arrow.triangle.pull",
                items: detail.openPullRequests
            )
            GitHubDetailItemList(
                title: "Recent issues",
                emptyTitle: "No open issues",
                systemImage: "smallcircle.filled.circle",
                items: detail.recentIssues
            )
        }
    }

    private func deliveryStatus(_ detail: GitHubRepositoryDetail) -> some View {
        BrandPanel {
            VStack(alignment: .leading, spacing: 16) {
                Text("Delivery status")
                    .font(.headline)
                LabeledContent("Latest workflow") {
                    if let run = detail.latestWorkflowRun {
                        Link(destination: run.url) {
                            Label(run.conclusion ?? run.status, systemImage: workflowSymbol(run))
                        }
                    } else {
                        Text("No workflow runs")
                            .foregroundStyle(.secondary)
                    }
                }
                Divider()
                LabeledContent("Latest release") {
                    if let release = detail.latestRelease {
                        Link(release.name ?? release.tagName, destination: release.url)
                    } else {
                        Text("No releases")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func workflowSymbol(_ run: GitHubWorkflowRun) -> String {
        switch run.conclusion {
        case "success": "checkmark.circle"
        case "failure", "cancelled", "timed_out": "xmark.circle"
        default: "clock"
        }
    }
}
