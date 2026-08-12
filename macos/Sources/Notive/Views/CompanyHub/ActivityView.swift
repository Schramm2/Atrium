import NotiveCore
import SwiftUI

/// Shared workspace activity feed.
struct ActivityView: View {
    @Environment(CompanyHubStore.self) private var hub

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    NotivePageHeader(
                        "Activity",
                        detail: "Everything that happened in the shared workspace, newest first."
                    ) {
                        Button("Mark all read", action: markAllRead)
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .disabled(hub.unreadActivityCount == 0)
                    }

                    if hub.activity.isEmpty {
                        HubEmptyState.notConnected(
                            "No activity",
                            systemImage: "bell",
                            appears: "Shares, agent runs, and comments from the shared workspace appear here, newest first.",
                            minHeight: 300
                        )
                    } else {
                        HubRowPanel(items: hub.activity) { event in
                            ActivityRow(event: event)
                        }
                    }
                }
                .padding(32)
                .frame(maxWidth: 980, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Activity")
        .task { await hub.loadActivity() }
    }

    private func markAllRead() {
        Task { await hub.markAllActivityRead() }
    }
}
